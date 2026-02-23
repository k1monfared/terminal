// ==UserScript==
// @name         Libby Audiobook Downloader
// @namespace    https://github.com/
// @version      1.4.0
// @description  Download audiobook MP3s directly from the OverDrive web player (post-ODM era)
// @match        https://*.listen.overdrive.com/*
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

    // -------------------------------------------------------------------------
    // Page-context collector (injected as <script> — no Xray wrapper restrictions)
    // -------------------------------------------------------------------------

    const PAGE_SCRIPT = `(function () {
        if (window.__libbyDlInstalled) return;
        window.__libbyDlInstalled = true;

        var URLS_KEY  = 'libby_dl_urls';
        var READY_KEY = 'libby_dl_ready';
        var captured  = [];
        sessionStorage.setItem(URLS_KEY, '[]');
        sessionStorage.removeItem(READY_KEY);

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

        // Walk every book part to trigger audio loading for each one
        function walk(compass, spool, i) {
            var part = compass.at(i);
            if (!part || part.bookMilliseconds === undefined || !isFinite(part.bookMilliseconds)) {
                console.log('[Libby DL] Walk complete. Total captured:', captured.length);
                sessionStorage.setItem(READY_KEY, '1');
                window.dispatchEvent(new Event('libby_dl_ready'));
                return;
            }
            spool.seekWithinBook(part.bookMilliseconds);
            setTimeout(function () { walk(compass, spool, i + 1); }, 400);
        }

        function init() {
            hookSeek();
            walk(BIF.objects.compass, BIF.objects.spool, 0);
        }

        // Wait for BIF player to be ready
        var waitTimer = setInterval(function () {
            if (typeof BIF !== 'undefined' &&
                BIF.objects && BIF.objects.compass && BIF.objects.spool) {
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
                reject(new Error('Collection timed out after 60s'));
            }, 60000);
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

    async function downloadAll(urls) {
        const title     = unsafeWindow.document.title
            .replace(/\s*[|\-–]\s*(OverDrive|Libby).*$/i, '').trim() || 'audiobook';
        const safeTitle = title.replace(/[<>:"/\\|?*\x00-\x1f]/g, '_').trim();
        const padWidth  = Math.max(3, String(urls.length).length);

        const filenames = urls.map((_, i) => {
            const n = String(i + 1).padStart(padWidth, '0');
            const p = String(i + 1).padStart(2, '0');
            return `${n}_Part${p}.mp3`;
        });

        const manifest = [
            `title="${safeTitle}"`,
            `author=""`,
            `files=(${filenames.map(f => `"${f}"`).join(' ')})`
        ].join('\n') + '\n';

        downloadManifest(manifest, 'libby_manifest.sh');

        // Download all parts in parallel — CDN URLs expire ~2 minutes after generation,
        // so sequential downloads would likely time out on longer books.
        const results = await Promise.allSettled(
            urls.map((url, i) => downloadPart(url, filenames[i]))
        );

        const failed = results.filter(r => r.status === 'rejected');
        if (failed.length > 0) {
            const msgs = failed.map(r => r.reason.message).join('\n');
            alert(`[Libby DL] ${urls.length - failed.length}/${urls.length} parts downloaded.\n\nFailed:\n${msgs}`);
        }

        return urls.length - failed.length;
    }

    // -------------------------------------------------------------------------
    // UI
    // -------------------------------------------------------------------------

    function addDownloadButton() {
        if (document.getElementById('libby-dl-btn')) return;

        const btn = document.createElement('button');
        btn.id    = 'libby-dl-btn';
        btn.title = 'Download Audiobook';
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
                let urls = JSON.parse(unsafeWindow.sessionStorage.getItem(URLS_KEY) || '[]');

                if (urls.length === 0) {
                    btn.title = 'Collecting audio URLs…';
                    urls = await collectURLs();
                }

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
