// ==UserScript==
// @name         Libby Audiobook Downloader
// @namespace    https://github.com/
// @version      1.7.5
// @description  Download audiobook MP3s (and supplementary-content PDFs) from the Libby/OverDrive web player (post-ODM era)
// @match        https://*.listen.libbyapp.com/*
// @match        https://*.read.libbyapp.com/*
// @match        https://*.listen.overdrive.com/*
// @match        https://*.read.overdrive.com/*
// @grant        GM_xmlhttpRequest
// @grant        unsafeWindow
// @connect      *
// @run-at       document-idle
// ==/UserScript==

// Architecture:
//
// URL capture runs inside a <script> tag injected into the PAGE context.
// This is necessary on Firefox because Tampermonkey's @grant sandbox uses Xray wrappers,
// which means prototype patches made via unsafeWindow don't affect the page's actual
// objects. Injecting a <script> tag bypasses this restriction entirely.
//
// Two capture hooks are used in the page script:
//   1. HTMLMediaElement.prototype.src setter — fires whenever the audio element loads a file
//   2. AudioProxyElem.prototype.seek (via requirejs) — fires when seek() is called with a URL
//
// Results are stored in sessionStorage and polled by the Tampermonkey script.
// Downloads use GM_xmlhttpRequest (bypasses CORS) and run in parallel since CDN URLs
// expire approximately 2 minutes after generation.

(function () {
    'use strict';

    const URLS_KEY  = 'libby_dl_urls';
    const READY_KEY = 'libby_dl_ready';
    const META_KEY  = 'libby_dl_meta';

    // Supplementary-content (read.overdrive.com) collection keys
    const IMGS_KEY   = 'libby_dl_imgs';
    const RMETA_KEY  = 'libby_dl_rmeta';
    const RREADY_KEY = 'libby_dl_rready';

    // Two outlets share this script: the audiobook "listen" player and the
    // supplementary-content "read" reader (a fixed-layout ebook = the bundled PDF).
    // The player runs in an iframe whose host is now *.listen.libbyapp.com /
    // *.read.libbyapp.com (formerly *.{listen,read}.overdrive.com); match either.
    const MODE = /\.read\.(libbyapp|overdrive)\.com$/.test(location.hostname) ? 'read' : 'listen';

    // Shared filename helpers (also used by the audiobook path).
    const sanitizeName = s => (s || '').replace(/[<>:"/\\|?*\x00-\x1f]/g, '_').trim();
    const slugify = s => (s || '').toLowerCase().normalize('NFKD')
        .replace(/[̀-ͯ]/g, '')
        .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 50) || 'audiobook';

    // -------------------------------------------------------------------------
    // Page-context collector (injected as <script> — no Xray wrapper restrictions)
    // -------------------------------------------------------------------------

    const PAGE_SCRIPT = `(function () {
        if (window.__libbyDlInstalled) return;
        window.__libbyDlInstalled = true;

        var URLS_KEY  = 'libby_dl_urls';
        var READY_KEY = 'libby_dl_ready';
        var META_KEY  = 'libby_dl_meta';
        var captured  = [];
        sessionStorage.setItem(URLS_KEY, '[]');
        sessionStorage.removeItem(READY_KEY);
        sessionStorage.removeItem(META_KEY);

        // Read metadata from the player's openbook manifest (BIF.map). No network:
        // the manifest is already loaded in the page.
        //   - title.main is the canonical title (subtitle is kept separate).
        //   - creator is an array of { name, role }, role lowercase
        //     ("author", "narrator", ...). The folder uses a single primary
        //     author's display name; the full list is kept in details.creators.
        // Raw fields (description HTML, toc/spine paths) are stored as-is and
        // formatted later in the Tampermonkey context, which keeps this injected
        // page script free of fragile escaping.
        function captureMeta() {
            var title = '', author = '', details = {};
            try {
                var m = (typeof BIF !== 'undefined' && BIF.map) ? BIF.map : null;
                if (m) {
                    if (m.title && m.title.main) title = m.title.main;

                    var creators = Array.isArray(m.creator)
                        ? m.creator.map(function (c) { return { name: c.name, role: c.role || '' }; })
                        : [];
                    var authors = creators.filter(function (c) { return /author/i.test(c.role); });
                    // Primary author display name for the folder ("First Last"),
                    // falling back to the first listed creator if none is tagged author.
                    author = (authors[0] || creators[0] || {}).name || '';

                    var crid = m['-odread-crid'];
                    if (Array.isArray(crid)) crid = crid[0];

                    var front = m.cover && m.cover.front;
                    var cover = front ? {
                        width:  front['-odread-width'],
                        height: front['-odread-height'],
                        color:  front['-odread-color']
                    } : null;

                    var spine = Array.isArray(m.spine) ? m.spine.map(function (s) {
                        return {
                            path:     s.path,
                            duration: s['audio-duration'] || 0,
                            bitrate:  s['audio-bitrate'] || 0,
                            bytes:    s['-odread-file-bytes'] || 0
                        };
                    }) : [];

                    details = {
                        subtitle:        (m.title && m.title.subtitle) || '',
                        creators:        creators,
                        descriptionHtml: (m.description && m.description.full) || '',
                        language:        m.language || '',
                        crid:            crid || '',
                        buid:            m['-odread-buid'] || '',
                        cover:           cover,
                        toc:             (m.nav && Array.isArray(m.nav.toc)) ? m.nav.toc : [],
                        spine:           spine
                    };
                }
            } catch (e) {
                console.warn('[Libby DL] captureMeta failed:', e.message);
            }
            // Only persist once the openbook manifest is actually populated, so an
            // early call (before BIF.map loads) cannot store blanks. Returns whether
            // metadata was captured so the caller can keep retrying until it is.
            if (!title) return false;
            sessionStorage.setItem(META_KEY, JSON.stringify({ title: title, author: author, details: details }));
            console.log('[Libby DL] Metadata — title="' + title + '" author="' + author + '"');
            return true;
        }

        function save(url) {
            if (!url || typeof url !== 'string') return;
            // seek() returns relative URLs like "%7BID%7DFmt425-Part01.mp3?cmpt=..."
            // Make them absolute using the current page origin.
            if (!url.startsWith('http')) url = window.location.origin + '/' + url;
            if (captured.indexOf(url) !== -1) return;
            captured.push(url);
            sessionStorage.setItem(URLS_KEY, JSON.stringify(captured));
            console.log('[Libby DL] Captured #' + captured.length + ':', url.split('/').pop().split('?')[0].slice(0, 60));
        }

        // Hook 1: HTMLMediaElement.prototype.src setter
        // Fires whenever the audio element's source is changed — catches file loads
        // even if seek() is never called with a URL string.
        var srcDesc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
        if (srcDesc && srcDesc.set) {
            Object.defineProperty(HTMLMediaElement.prototype, 'src', {
                set: function (v) { save(v); srcDesc.set.call(this, v); },
                get: srcDesc.get,
                configurable: true
            });
            console.log('[Libby DL] HTMLMediaElement.src hooked');
        }

        // Hook 2: AudioProxyElem.prototype.seek (via requirejs)
        // Some OverDrive versions pass the URL string here; log what it receives
        // regardless so we can see in the console whether it is a URL or a number.
        function hookSeek() {
            if (typeof requirejs === 'undefined') return;
            try {
                requirejs(['bifocal/themes/read/default/src/parts/audio-proxy-element'], function (elem) {
                    var orig = elem.prototype.seek;
                    elem.prototype.seek = function (t) {
                        console.log('[Libby DL] seek() type=' + typeof t + ' value=' + JSON.stringify(t));
                        save(t);
                        return orig.apply(this, arguments);
                    };
                    console.log('[Libby DL] AudioProxyElem.seek hooked');
                });
            } catch (e) {
                console.warn('[Libby DL] requirejs hook failed:', e.message);
            }
        }

        // Map a captured URL to its part number, e.g. "...Fmt425-Part07.mp3?..." -> 7
        function partOf(u) {
            try { u = decodeURIComponent(u || ''); } catch (e) {}
            var mm = u.split('#')[0].match(/Part(\\d+)\\.mp3/i);
            return mm ? parseInt(mm[1], 10) : null;
        }
        function capturedPartSet() {
            var s = {};
            for (var k = 0; k < captured.length; k++) { var n = partOf(captured[k]); if (n != null) s[n] = 1; }
            return s;
        }
        function capturedPartCount() { return Object.keys(capturedPartSet()).length; }
        function totalParts() {
            return (typeof BIF !== 'undefined' && BIF.map && Array.isArray(BIF.map.spine)) ? BIF.map.spine.length : 0;
        }

        // Build a seek target INSIDE every spine part. Walking the compass (chapter
        // navigation) instead deterministically MISSES any part that contains no chapter
        // boundary — that part is never seeked into, so it never loads, no matter how
        // many passes run. Offsets are the cumulative sum of each part's audio-duration
        // (seconds -> ms); we aim a few seconds into the part so boundary rounding can't
        // land us on the previous one.
        function spineSeekPlan() {
            var spine = (typeof BIF !== 'undefined' && BIF.map && Array.isArray(BIF.map.spine)) ? BIF.map.spine : [];
            var plan = [], acc = 0;
            for (var i = 0; i < spine.length; i++) {
                var dur = (spine[i]['audio-duration'] || 0) * 1000;
                var pn  = partOf(spine[i].path);
                plan.push({ part: pn != null ? pn : (i + 1), seekMs: acc + (dur > 0 ? Math.min(5000, dur / 2) : 0) });
                acc += dur;
            }
            return plan;
        }

        // Persist results and signal the Tampermonkey side that collection is done.
        function finishWalk() {
            var got = capturedPartCount(), total = totalParts();
            console.log('[Libby DL] Walk complete. Captured ' + got + '/' + total + ' parts.');
            sessionStorage.setItem(READY_KEY, '1');
            window.dispatchEvent(new Event('libby_dl_ready'));
        }

        var WALK_MAX_PASSES = 8;     // hard cap so a stuck book can never loop forever
        var SETTLE_MS = 1500;        // wait after a sweep so a late signed URL can register

        // Primary sweep: seek directly to a target inside each spine part (needs
        // audio-duration). Seeks only to parts not yet captured. Each part's URL is
        // server-signed per spine index, so we must make the player load every one —
        // a distant part's URL sometimes arrives a beat after the sweep ends, so we let
        // the captures settle, then retry the still-missing parts. Keep retrying until a
        // whole pass adds nothing new (loads have stalled) rather than a fixed count, so
        // slow networks get the time they need; WALK_MAX_PASSES is just a safety cap.
        function walk(spool, plan, i, pass, prevGot) {
            var have = capturedPartSet();
            while (i < plan.length && have[plan[i].part]) i++;   // skip already-captured parts
            if (i >= plan.length) {
                if (capturedPartCount() >= totalParts()) { finishWalk(); return; }   // all in: no wait
                setTimeout(function () {
                    var got = capturedPartCount(), total = totalParts();
                    if (got < total && got > prevGot && pass + 1 < WALK_MAX_PASSES) {
                        console.log('[Libby DL] Pass ' + (pass + 1) + ': ' + got + '/' + total + ' parts — retrying missing.');
                        walk(spool, spineSeekPlan(), 0, pass + 1, got);   // rebuild plan in case spine changed
                        return;
                    }
                    finishWalk();
                }, SETTLE_MS);
                return;
            }
            spool.seekWithinBook(plan[i].seekMs);
            setTimeout(function () { walk(spool, plan, i + 1, pass, prevGot); }, 400);
        }

        // Fallback sweep: used when the manifest has no per-part audio-duration, so the
        // spine offsets cannot be computed. Seek to every compass navigation point. This
        // can miss parts that contain no chapter boundary (the reason the spine walk
        // exists), but it is the best available without durations.
        function walkCompass(compass, spool, i, pass) {
            var part = compass.at(i);
            if (!part || part.bookMilliseconds === undefined || !isFinite(part.bookMilliseconds)) {
                var have = capturedPartCount(), total = totalParts();
                if (have < total && pass + 1 < WALK_MAX_PASSES) {
                    console.log('[Libby DL] Pass ' + (pass + 1) + ': ' + have + '/' + total + ' parts — sweeping again.');
                    walkCompass(compass, spool, 0, pass + 1);
                    return;
                }
                finishWalk();
                return;
            }
            spool.seekWithinBook(part.bookMilliseconds);
            setTimeout(function () { walkCompass(compass, spool, i + 1, pass); }, 400);
        }

        function init() {
            // BIF.map can still lag slightly behind compass/spool, so keep retrying
            // the metadata capture until the manifest is populated.
            if (!captureMeta()) {
                var metaTimer = setInterval(function () {
                    if (captureMeta()) clearInterval(metaTimer);
                }, 250);
                setTimeout(function () { clearInterval(metaTimer); }, 20000);
            }
            hookSeek();
            // Prefer direct per-part seeks (needs audio-duration); fall back to compass
            // navigation when the manifest provides no durations.
            var spine = (typeof BIF !== 'undefined' && BIF.map && Array.isArray(BIF.map.spine)) ? BIF.map.spine : [];
            var hasDur = spine.some(function (s) { return (s['audio-duration'] || 0) > 0; });
            if (hasDur) {
                walk(BIF.objects.spool, spineSeekPlan(), 0, 0, -1);
            } else {
                console.log('[Libby DL] No spine durations — using compass-navigation fallback.');
                walkCompass(BIF.objects.compass, BIF.objects.spool, 0, 0);
            }
        }

        // Wait until the player is FULLY ready before walking: the audio engine
        // (compass/spool) AND the openbook manifest (title + spine) must all be
        // loaded. Starting too early captures only some parts and blank metadata.
        function ready() {
            return typeof BIF !== 'undefined' &&
                BIF.objects && BIF.objects.compass && BIF.objects.spool &&
                BIF.map && BIF.map.title && BIF.map.title.main &&
                Array.isArray(BIF.map.spine) && BIF.map.spine.length > 0;
        }
        var waitTimer = setInterval(function () {
            if (ready()) {
                clearInterval(waitTimer);
                init();
            }
        }, 250);
        setTimeout(function () { clearInterval(waitTimer); }, 30000);

        console.log('[Libby DL] Collector installed in page context');
    })();`;

    function injectCollector() {
        if (document.getElementById('libby-dl-collector')) return;
        const s = document.createElement('script');
        s.id = 'libby-dl-collector';
        s.textContent = PAGE_SCRIPT;
        (document.head || document.documentElement).appendChild(s);
    }

    // -------------------------------------------------------------------------
    // URL collection (polls sessionStorage set by page script)
    // -------------------------------------------------------------------------

    async function collectURLs() {
        unsafeWindow.sessionStorage.setItem(URLS_KEY, '[]');
        unsafeWindow.sessionStorage.removeItem(READY_KEY);
        unsafeWindow.sessionStorage.removeItem(META_KEY);
        injectCollector();

        await new Promise((resolve, reject) => {
            const check = setInterval(() => {
                if (unsafeWindow.sessionStorage.getItem(READY_KEY) === '1') {
                    clearInterval(check);
                    resolve();
                }
            }, 300);
            setTimeout(() => {
                clearInterval(check);
                reject(new Error('Collection timed out after 120s'));
            }, 120000);
        });

        const urls = JSON.parse(unsafeWindow.sessionStorage.getItem(URLS_KEY) || '[]');
        const unique = [...new Set(urls)];
        console.log(`[Libby DL] Collection done — ${unique.length} unique URLs`);
        return unique;
    }

    // -------------------------------------------------------------------------
    // Download
    // -------------------------------------------------------------------------

    // GM_xmlhttpRequest bypasses CORS. The ArrayBuffer response is wrapped in
    // unsafeWindow.Blob/Uint8Array to keep everything in the page security context,
    // which is required for anchor-click downloads in Firefox.
    function downloadPart(url, filename) {
        return new Promise((resolve, reject) => {
            GM_xmlhttpRequest({
                method: 'GET',
                url,
                responseType: 'arraybuffer',
                onload(r) {
                    if (r.status < 200 || r.status >= 300) {
                        reject(new Error(`HTTP ${r.status} for ${filename}`));
                        return;
                    }
                    try {
                        const bytes   = new unsafeWindow.Uint8Array(r.response);
                        const blob    = new unsafeWindow.Blob([bytes], { type: 'audio/mpeg' });
                        const blobUrl = unsafeWindow.URL.createObjectURL(blob);
                        const a       = unsafeWindow.document.createElement('a');
                        a.href        = blobUrl;
                        a.download    = filename;
                        unsafeWindow.document.body.appendChild(a);
                        a.click();
                        unsafeWindow.document.body.removeChild(a);
                        setTimeout(() => unsafeWindow.URL.revokeObjectURL(blobUrl), 60000);
                        console.log(`[Libby DL] Downloaded: ${filename}`);
                        resolve();
                    } catch (e) { reject(e); }
                },
                onerror()  { reject(new Error('Network error: ' + filename)); },
                ontimeout() { reject(new Error('Timeout: ' + filename)); },
            });
        });
    }

    function downloadManifest(content, filename) {
        const blob    = new unsafeWindow.Blob([content], { type: 'text/plain' });
        const blobUrl = unsafeWindow.URL.createObjectURL(blob);
        const a       = unsafeWindow.document.createElement('a');
        a.href        = blobUrl;
        a.download    = filename;
        unsafeWindow.document.body.appendChild(a);
        a.click();
        unsafeWindow.document.body.removeChild(a);
        setTimeout(() => unsafeWindow.URL.revokeObjectURL(blobUrl), 10000);
    }

    function downloadBytes(bytes, filename, type) {
        const blob    = new unsafeWindow.Blob([bytes], { type: type || 'application/octet-stream' });
        const blobUrl = unsafeWindow.URL.createObjectURL(blob);
        const a       = unsafeWindow.document.createElement('a');
        a.href        = blobUrl;
        a.download    = filename;
        unsafeWindow.document.body.appendChild(a);
        a.click();
        unsafeWindow.document.body.removeChild(a);
        setTimeout(() => unsafeWindow.URL.revokeObjectURL(blobUrl), 60000);
    }

    // -------------------------------------------------------------------------
    // Supplementary content (read.overdrive.com) — a fixed-layout ebook whose
    // pages are scanned images of the bundled PDF. We walk every page, read each
    // page image from its (same-origin) iframe, re-encode to JPEG, and assemble a
    // single PDF. Each supplement is its own reader (its own CRID), so multiple
    // supplements are handled independently and named uniquely by a short CRID id.
    // -------------------------------------------------------------------------

    const READ_PAGE_SCRIPT = `(function () {
        if (window.__libbyReadInstalled) return;
        window.__libbyReadInstalled = true;

        var IMGS_KEY = 'libby_dl_imgs', RMETA_KEY = 'libby_dl_rmeta', RREADY_KEY = 'libby_dl_rready';
        sessionStorage.removeItem(IMGS_KEY);
        sessionStorage.removeItem(RMETA_KEY);
        sessionStorage.removeItem(RREADY_KEY);

        function getMeta() {
            var title = '', author = '', crid = '';
            try {
                var m = BIF.map;
                if (m.title && m.title.main) title = m.title.main;
                if (Array.isArray(m.creator)) {
                    var a = m.creator.filter(function (c) { return /author/i.test(c.role || ''); });
                    author = (a[0] || m.creator[0] || {}).name || '';
                }
                crid = m['-odread-crid'];
                if (Array.isArray(crid)) crid = crid[0];
            } catch (e) {}
            return { title: title, author: author, crid: crid || '' };
        }

        // The current page renders in a same-origin <iframe src=".../pages/N.xhtml">;
        // its single <img> is the page image (served unsigned).
        function pageImg(pageNum) {
            var ifr = document.querySelectorAll('iframe');
            for (var i = 0; i < ifr.length; i++) {
                if ((ifr[i].src || '').indexOf('/pages/' + pageNum + '.xhtml') !== -1) {
                    try {
                        var im = ifr[i].contentDocument && ifr[i].contentDocument.querySelector('img');
                        if (im && im.src) return im.src;
                    } catch (e) {}
                }
            }
            return null;
        }

        function run() {
            var compass = BIF.objects.compass;
            var total = BIF.map.spine.length;
            var images = new Array(total).fill(null);
            var i = 0, tries = 0;
            function step() {
                var url = pageImg(i + 1);
                if (url) { images[i] = url; i++; tries = 0; }
                else {
                    if (tries === 0) { try { compass.seek(i); } catch (e) {} }
                    if (++tries > 25) { i++; tries = 0; }   // skip a page that never rendered
                }
                if (i < total) { setTimeout(step, 150); return; }
                sessionStorage.setItem(IMGS_KEY, JSON.stringify(images));
                sessionStorage.setItem(RMETA_KEY, JSON.stringify(getMeta()));
                sessionStorage.setItem(RREADY_KEY, '1');
                window.dispatchEvent(new Event('libby_dl_rready'));
                console.log('[Libby DL] Supplement pages captured:', images.filter(Boolean).length + '/' + total);
            }
            step();
        }

        var t = setInterval(function () {
            if (typeof BIF !== 'undefined' && BIF.objects && BIF.objects.compass &&
                BIF.map && Array.isArray(BIF.map.spine) && BIF.map.spine.length > 0) {
                clearInterval(t);
                run();
            }
        }, 250);
        setTimeout(function () { clearInterval(t); }, 30000);
    })();`;

    function injectReadCollector() {
        if (document.getElementById('libby-read-collector')) return;
        const s = document.createElement('script');
        s.id = 'libby-read-collector';
        s.textContent = READ_PAGE_SCRIPT;
        (document.head || document.documentElement).appendChild(s);
    }

    async function collectPages() {
        unsafeWindow.sessionStorage.removeItem(IMGS_KEY);
        unsafeWindow.sessionStorage.removeItem(RMETA_KEY);
        unsafeWindow.sessionStorage.removeItem(RREADY_KEY);
        injectReadCollector();

        await new Promise((resolve, reject) => {
            const check = setInterval(() => {
                if (unsafeWindow.sessionStorage.getItem(RREADY_KEY) === '1') { clearInterval(check); resolve(); }
            }, 300);
            setTimeout(() => { clearInterval(check); reject(new Error('Page collection timed out after 120s')); }, 120000);
        });

        const images = JSON.parse(unsafeWindow.sessionStorage.getItem(IMGS_KEY) || '[]');
        const meta   = JSON.parse(unsafeWindow.sessionStorage.getItem(RMETA_KEY) || '{}');
        console.log(`[Libby DL] Collected ${images.filter(Boolean).length}/${images.length} page images`);
        return { images, meta };
    }

    function fetchBytes(url) {
        return new Promise((resolve, reject) => {
            GM_xmlhttpRequest({
                method: 'GET', url, responseType: 'arraybuffer',
                onload(r) {
                    if (r.status < 200 || r.status >= 300) { reject(new Error('HTTP ' + r.status)); return; }
                    resolve(new unsafeWindow.Uint8Array(r.response));
                },
                onerror()  { reject(new Error('Network error')); },
                ontimeout() { reject(new Error('Timeout')); },
            });
        });
    }

    // Fetch a page image and re-encode to JPEG (canvas) for compact DCTDecode embedding.
    async function imageToJpeg(url) {
        const bytes = await fetchBytes(url);
        const blob  = new unsafeWindow.Blob([bytes]);
        const bmp   = await unsafeWindow.createImageBitmap(blob);
        const cv    = unsafeWindow.document.createElement('canvas');
        cv.width = bmp.width; cv.height = bmp.height;
        cv.getContext('2d').drawImage(bmp, 0, 0);
        const jblob = await new Promise(res => cv.toBlob(res, 'image/jpeg', 0.9));
        const jbytes = new unsafeWindow.Uint8Array(await jblob.arrayBuffer());
        return { buf: jbytes, w: bmp.width, h: bmp.height };
    }

    // Minimal PDF writer: one image XObject (DCTDecode) per page, drawn to fill its page.
    function buildPdf(pages) {
        const enc = new TextEncoder();
        const chunks = []; let len = 0; const offsets = [];
        const push = d => { const b = typeof d === 'string' ? enc.encode(d) : d; chunks.push(b); len += b.length; };
        const obj  = (n, body) => { offsets[n] = len; push(`${n} 0 obj\n`); push(body); push('\nendobj\n'); };

        push('%PDF-1.3\n');
        let id = 3; const objs = []; const kids = [];
        for (let i = 0; i < pages.length; i++) {
            const pageId = id++, contId = id++, imgId = id++;
            objs.push({ pageId, contId, imgId, p: pages[i] });
            kids.push(`${pageId} 0 R`);
        }
        obj(1, '<</Type/Catalog/Pages 2 0 R>>');
        obj(2, `<</Type/Pages/Kids[${kids.join(' ')}]/Count ${pages.length}>>`);
        for (const o of objs) {
            const { w, h, buf } = o.p;
            obj(o.pageId, `<</Type/Page/Parent 2 0 R/MediaBox[0 0 ${w} ${h}]/Resources<</XObject<</Im0 ${o.imgId} 0 R>>>>/Contents ${o.contId} 0 R>>`);
            const content = `q\n${w} 0 0 ${h} 0 0 cm\n/Im0 Do\nQ\n`;
            obj(o.contId, `<</Length ${content.length}>>\nstream\n${content}endstream`);
            offsets[o.imgId] = len;
            push(`${o.imgId} 0 obj\n<</Type/XObject/Subtype/Image/Width ${w}/Height ${h}/ColorSpace/DeviceRGB/BitsPerComponent 8/Filter/DCTDecode/Length ${buf.length}>>\nstream\n`);
            push(buf); push('\nendstream\nendobj\n');
        }
        const xrefStart = len;
        const total = id;
        push(`xref\n0 ${total}\n0000000000 65535 f \n`);
        for (let n = 1; n < total; n++) push(String(offsets[n]).padStart(10, '0') + ' 00000 n \n');
        push(`trailer\n<</Size ${total}/Root 1 0 R>>\nstartxref\n${xrefStart}\n%%EOF`);

        const out = new unsafeWindow.Uint8Array(len);
        let p = 0; for (const c of chunks) { out.set(c, p); p += c.length; }
        return out;
    }

    async function downloadSupplement(images, meta) {
        const valid = images.filter(Boolean);
        if (valid.length === 0) { alert('[Libby DL] No supplement pages were captured.'); return 0; }

        const pages = [];
        for (const url of valid) {
            try { pages.push(await imageToJpeg(url)); }
            catch (e) { console.warn('[Libby DL] page fetch failed:', e.message); }
        }
        if (pages.length === 0) { alert('[Libby DL] Could not fetch any supplement pages.'); return 0; }

        const crid8    = String(meta.crid || '').replace(/[^a-z0-9]/gi, '').slice(0, 8) || String(valid.length);
        // Name the PDF by the supplement's own exposed title, plus a short CRID id so
        // multiple supplements (which can share a title) never collide in ~/Downloads.
        // No "<slug>__" prefix is needed: the CRID id already makes it unique, and the
        // file lands in the right folder via the manifest's title/author.
        const baseName = sanitizeName(meta.title) || 'supplement';
        const pdfName  = `${baseName}-${crid8}.pdf`;

        downloadBytes(buildPdf(pages), pdfName, 'application/pdf');

        const manifest = [
            `title="${sanitizeName(meta.title)}"`,
            `author="${sanitizeName(meta.author)}"`,
            `kind="supplement"`,
            `files=("${pdfName}")`
        ].join('\n') + '\n';
        // Unique manifest name (title slug + supplement CRID); libby_get globs *__libby_manifest.sh.
        downloadManifest(manifest, `${slugify(meta.title)}-${crid8}__libby_manifest.sh`);

        const missing = valid.length - pages.length;
        if (missing > 0) alert(`[Libby DL] Supplement: ${pages.length}/${valid.length} pages saved (${missing} failed).`);
        return pages.length;
    }

    // -------------------------------------------------------------------------
    // Metadata (loglog) — gathered from two sources and written to one file:
    //   1. the in-page openbook manifest (BIF.map), captured by the page script
    //   2. OverDrive's public Thunder catalog API, fetched here by CRID
    // Fetched via GM_xmlhttpRequest so the cross-origin call bypasses CORS.
    // -------------------------------------------------------------------------

    function fetchJSON(url) {
        // Resolves null on any failure so metadata never blocks the audio download.
        return new Promise((resolve) => {
            try {
                GM_xmlhttpRequest({
                    method: 'GET',
                    url,
                    responseType: 'json',
                    onload(r) {
                        if (r.status < 200 || r.status >= 300) { resolve(null); return; }
                        try { resolve(r.response || JSON.parse(r.responseText)); }
                        catch (e) { resolve(null); }
                    },
                    onerror()  { resolve(null); },
                    ontimeout() { resolve(null); },
                });
            } catch (e) { resolve(null); }
        });
    }

    function htmlToText(html) {
        if (!html) return '';
        const div = unsafeWindow.document.createElement('div');
        div.innerHTML = String(html)
            .replace(/<\s*br\s*\/?>/gi, '\n')
            .replace(/<\/\s*(p|div|li|h[1-6])\s*>/gi, '\n');
        return (div.textContent || '').replace(/[ \t]+/g, ' ').replace(/\n{3,}/g, '\n\n').trim();
    }

    function partNum(p) {
        try { p = decodeURIComponent(p || ''); } catch (e) {}
        const mm = p.split('#')[0].match(/Part(\d+)\.mp3/i);
        return mm ? parseInt(mm[1], 10) : null;
    }

    function fmtDuration(totalSec) {
        totalSec = Math.round(totalSec || 0);
        const h = Math.floor(totalSec / 3600);
        const m = Math.floor((totalSec % 3600) / 60);
        const s = totalSec % 60;
        const pad = n => String(n).padStart(2, '0');
        return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
    }

    // Build a nested loglog document (4-space indent per level) merging both sources.
    function buildMetadataLog(meta, thunder) {
        const d = meta.details || {};
        const t = thunder || {};
        const lines = [];
        const add = (depth, text) => lines.push('    '.repeat(depth) + '- ' + text);
        const one = v => String(v == null ? '' : v).replace(/\s+/g, ' ').trim();

        add(0, 'Audiobook Metadata');

        // Title (subtitle recorded here, but deliberately not in the folder name)
        add(1, 'Title');
        add(2, 'Main: ' + one(meta.title || t.title));
        const subtitle = d.subtitle || t.subtitle;
        if (subtitle) add(2, 'Subtitle: ' + one(subtitle));
        if (t.edition) add(2, 'Edition: ' + one(t.edition));

        // Creators (all authors + narrators, with roles)
        const creators = (d.creators && d.creators.length)
            ? d.creators
            : (t.creators || []).map(c => ({ name: c.name, role: c.role }));
        if (creators.length) {
            add(1, 'Creators');
            creators.forEach(c => {
                const role = one(c.role) || 'contributor';
                add(2, role.charAt(0).toUpperCase() + role.slice(1) + ': ' + one(c.name));
            });
        }

        // Identifiers
        const crid = d.crid || t.id;
        const formats = t.formats || [];
        const isbn = (formats.find(f => f.isbn) || {}).isbn;
        add(1, 'Identifiers');
        if (crid)    add(2, 'CRID: ' + one(crid));
        if (d.buid)  add(2, 'BUID: ' + one(d.buid));
        if (isbn)    add(2, 'ISBN: ' + one(isbn));

        // Publication
        const lang = (t.languages && t.languages[0] && t.languages[0].name) || d.language;
        if (t.publisher || t.publishDateText || lang) {
            add(1, 'Publication');
            if (t.publisher && t.publisher.name) add(2, 'Publisher: ' + one(t.publisher.name));
            if (t.publishDateText)               add(2, 'Published: ' + one(t.publishDateText));
            if (lang)                            add(2, 'Language: ' + one(lang));
        }

        // Ratings
        if (t.starRating || t.popularity != null) {
            add(1, 'Ratings');
            if (t.starRating)        add(2, `Stars: ${t.starRating} (${t.starRatingCount || 0} ratings)`);
            if (t.popularity != null) add(2, 'Popularity: ' + t.popularity);
            if (t.unitsSold != null)  add(2, 'Units sold: ' + t.unitsSold);
        }

        // Subjects
        const subjects = (t.subjects || []).map(s => s.name || s);
        const bisac = t.bisac || [];
        if (subjects.length || bisac.length) {
            add(1, 'Subjects');
            subjects.forEach(s => add(2, one(s)));
            if (bisac.length) {
                add(2, 'BISAC');
                bisac.forEach(b => add(3, one(b.code) + ': ' + one(b.description)));
            }
        }

        // Audio summary
        const spine = d.spine || [];
        const totalSec = spine.reduce((a, s) => a + (s.duration || 0), 0);
        const totalDur = (formats.find(f => f.duration) || {}).duration;
        add(1, 'Audio');
        add(2, 'Total duration: ' + (totalDur || fmtDuration(totalSec)));
        if (spine.length)             add(2, 'Parts: ' + spine.length);
        if (spine[0] && spine[0].bitrate) add(2, 'Bitrate: ' + spine[0].bitrate + ' kbps');

        // Description (one item per paragraph)
        const descText = htmlToText(d.descriptionHtml) ||
            htmlToText(t.fullDescription || t.shortDescription);
        if (descText) {
            add(1, 'Description');
            descText.split(/\n+/).map(p => p.trim()).filter(Boolean).forEach(p => add(2, p));
        }

        // Chapters (table of contents)
        const toc = d.toc || [];
        if (toc.length) {
            add(1, 'Chapters');
            toc.forEach((c, i) => {
                const n = String(i + 1).padStart(2, '0');
                const pn = partNum(c.path);
                add(2, `${n}: ${one(c.title)}${pn ? ' -> Part' + String(pn).padStart(2, '0') : ''}`);
            });
        }

        // Parts (spine)
        if (spine.length) {
            add(1, 'Parts');
            spine.forEach((s, i) => {
                const pn = partNum(s.path);
                const label = 'Part' + String(pn != null ? pn : i + 1).padStart(2, '0');
                add(2, `${label}: ${fmtDuration(s.duration)}, ${s.bitrate || '?'} kbps, ${s.bytes || '?'} bytes`);
            });
        }

        // Cover
        const covers = t.covers || {};
        const coverUrl = (covers.cover510Wide || covers.cover300Wide || covers.cover150Wide || {}).href;
        if (coverUrl || d.cover) {
            add(1, 'Cover');
            if (coverUrl) add(2, 'URL: ' + coverUrl);
            if (d.cover && d.cover.width)  add(2, `Dimensions: ${d.cover.width}x${d.cover.height}`);
            if (d.cover && d.cover.color)  add(2, 'Dominant color: rgb(' + d.cover.color.join(', ') + ')');
        }

        // Sources
        add(1, 'Sources');
        add(2, 'In-page openbook manifest (BIF.map)');
        add(2, crid
            ? `OverDrive Thunder API: https://thunder.api.overdrive.com/v2/media/${crid}`
            : 'OverDrive Thunder API: (unavailable)');

        return lines.join('\n') + '\n';
    }

    async function downloadAll(urls) {
        // Title + author captured from the player's openbook manifest (BIF.map),
        // stored in sessionStorage by the page collector. Fall back to the page
        // title if metadata is unavailable.
        let meta = {};
        try { meta = JSON.parse(unsafeWindow.sessionStorage.getItem(META_KEY) || '{}'); } catch (e) {}

        const sanitize  = s => (s || '').replace(/[<>:"/\\|?*\x00-\x1f]/g, '_').trim();
        const rawTitle  = (meta.title || unsafeWindow.document.title
            .replace(/\s*[|\-–]\s*(OverDrive|Libby).*$/i, '')).trim() || 'audiobook';
        const safeTitle = sanitize(rawTitle);
        const safeAuthor = sanitize(meta.author);

        // Gather catalog metadata from Thunder (best-effort) and build the loglog file.
        const crid = meta.details && meta.details.crid;
        let thunder = null;
        if (crid) thunder = await fetchJSON(`https://thunder.api.overdrive.com/v2/media/${encodeURIComponent(crid)}`);
        let metadataLog = '';
        try { metadataLog = buildMetadataLog(meta, thunder); }
        catch (e) { console.warn('[Libby DL] metadata log build failed:', e.message); }

        // Number files by the TRUE part number parsed from each CDN URL, sorted by
        // it. Capture order is not always part order, so naming by capture index
        // would mislabel files; sorting by the real part keeps playback correct and
        // makes any un-captured part show up as a numbering gap rather than a
        // silently mislabeled file.
        const spine = (meta.details && meta.details.spine) || [];
        const expectedParts = spine.map(s => partNum(s.path)).filter(n => n != null);
        const maxPart = Math.max(urls.length, expectedParts.length, ...expectedParts, 0);
        const padWidth = Math.max(3, String(maxPart).length);

        const parsed = urls.map(url => ({ url, part: partNum(url) }));
        parsed.sort((a, b) => {
            if (a.part == null) return 1;
            if (b.part == null) return -1;
            return a.part - b.part;
        });
        const orderedUrls = parsed.map(p => p.url);

        // Per-book filename prefix so downloading several books before running
        // libby_get does not collide in ~/Downloads (Firefox would otherwise rename
        // clashes to "(1)" and interleave books). The "<slug>__" prefix is stripped
        // by libby_get when moving files into the final "Author - Title" folder.
        const slugify = s => (s || '').toLowerCase().normalize('NFKD')
            .replace(/[̀-ͯ]/g, '')
            .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 50) || 'audiobook';
        const prefix = slugify(meta.title || rawTitle) + '__';

        // Single zero-padded part number: "Part017.mp3". Padding keeps the lexical
        // sort correct (Part017 before Part002 would be wrong unpadded); one number
        // avoids the redundant "017_Part17" pair the old "<nnn>_Part<pp>" form produced.
        const filenames = parsed.map((p, i) => {
            const num = p.part != null ? p.part : (i + 1);
            return `${prefix}Part${String(num).padStart(padWidth, '0')}.mp3`;
        });

        // Flag expected parts (from the spine) that were never captured.
        const capturedParts = new Set(parsed.map(p => p.part).filter(n => n != null));
        const missing = expectedParts.filter(n => !capturedParts.has(n));

        const metadataName = `${prefix}libby_metadata.log`;
        const manifest = [
            `title="${safeTitle}"`,
            `author="${safeAuthor}"`,
            `metadata="${metadataName}"`,
            `files=(${filenames.map(f => `"${f}"`).join(' ')})`
        ].join('\n') + '\n';

        downloadManifest(manifest, `${prefix}libby_manifest.sh`);
        if (metadataLog) downloadManifest(metadataLog, metadataName);

        // Download all parts in parallel — CDN URLs expire ~2 minutes after generation,
        // so sequential downloads would likely time out on longer books.
        const results = await Promise.allSettled(
            orderedUrls.map((url, i) => downloadPart(url, filenames[i]))
        );

        const failed = results.filter(r => r.status === 'rejected');
        let warn = '';
        if (missing.length) {
            warn += `\n\nMissing ${missing.length} part(s) the player never loaded: ` +
                missing.map(n => 'Part' + String(n).padStart(2, '0')).join(', ') +
                `.\nReload the player, wait until it is fully loaded, then click ⬇ again.`;
        }
        if (failed.length > 0) {
            warn += '\n\nFailed downloads:\n' + failed.map(r => r.reason.message).join('\n');
        }
        if (warn) {
            alert(`[Libby DL] ${orderedUrls.length - failed.length}/${orderedUrls.length} parts downloaded.${warn}`);
        }

        return orderedUrls.length - failed.length;
    }

    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------

    function addDownloadButton() {
        if (document.getElementById('libby-dl-btn')) return;

        const btn = document.createElement('button');
        btn.id    = 'libby-dl-btn';
        btn.title = MODE === 'read' ? 'Download Supplementary PDF' : 'Download Audiobook';
        btn.textContent = '⬇';
        Object.assign(btn.style, {
            position:     'fixed',
            top:          '10px',
            right:        '10px',
            zIndex:       '99999',
            background:   '#1d65a6',
            color:        'white',
            border:       'none',
            borderRadius: '6px',
            padding:      '8px 14px',
            fontSize:     '20px',
            cursor:       'pointer',
            boxShadow:    '0 2px 8px rgba(0,0,0,0.35)',
            fontFamily:   'sans-serif',
            lineHeight:   '1',
        });

        btn.addEventListener('mouseenter', () => { btn.style.background = '#1550a0'; });
        btn.addEventListener('mouseleave', () => {
            if (!btn.dataset.done) btn.style.background = '#1d65a6';
        });

        btn.addEventListener('click', async () => {
            btn.disabled = true;
            btn.textContent = '…';
            btn.style.background = '#888';
            delete btn.dataset.done;

            try {
                if (MODE === 'read') {
                    // Supplementary-content PDF: walk pages, assemble one PDF.
                    btn.title = 'Collecting supplement pages…';
                    const { images, meta } = await collectPages();
                    const have = images.filter(Boolean).length;
                    if (have === 0) {
                        alert('[Libby DL] No supplement pages found.\n\nWait for the reader to fully load, then click ⬇ again.');
                        return;
                    }
                    btn.textContent = '⬇';
                    btn.title = `Building PDF (${have} pages)…`;
                    btn.style.background = '#2a8a2a';
                    const n = await downloadSupplement(images, meta);
                    btn.textContent = '✓';
                    btn.title = `Done: supplement PDF (${n} pages) → run libby_get in terminal`;
                    btn.style.background = '#2a8a2a';
                    btn.dataset.done = '1';
                    return;
                }

                // Always re-collect: a stale URL list cached in sessionStorage (it
                // survives reloads within a tab) would otherwise skip collection and
                // the metadata capture that runs with it. collectURLs() clears the
                // URLS/META/READY keys before injecting the collector.
                btn.title = 'Collecting audio URLs…';
                const urls = await collectURLs();

                if (urls.length === 0) {
                    alert('[Libby DL] No audio URLs found.\n\nCheck the browser console for "[Libby DL]" lines to diagnose.');
                    return;
                }

                btn.textContent = '⬇';
                btn.title = `Downloading ${urls.length} parts…`;
                btn.style.background = '#2a8a2a';

                const ok = await downloadAll(urls);

                btn.textContent = '✓';
                btn.title = `Done: ${ok}/${urls.length} parts + manifest → run libby_get in terminal`;
                btn.style.background = '#2a8a2a';
                btn.dataset.done = '1';
            } catch (err) {
                console.error('[Libby DL]', err);
                alert(`[Libby DL] Error: ${err.message}`);
                btn.textContent = '⬇';
                btn.style.background = '#1d65a6';
            } finally {
                btn.disabled = false;
            }
        });

        document.body.appendChild(btn);
        console.log('[Libby DL] Download button added.');

        // Re-append if SPA re-renders and removes it
        setInterval(() => {
            if (!document.getElementById('libby-dl-btn') && document.body) {
                document.body.appendChild(btn);
            }
        }, 500);
    }

    if (document.body) {
        addDownloadButton();
    } else {
        document.addEventListener('DOMContentLoaded', addDownloadButton);
    }
})();
