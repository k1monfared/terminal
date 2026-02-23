// ==UserScript==
// @name         Libby Audiobook Downloader
// @namespace    https://github.com/
// @version      1.2.0
// @description  Download audiobook MP3s directly from the OverDrive web player (post-ODM era)
// @match        https://*.listen.overdrive.com/*
// @grant        GM_download
// @grant        unsafeWindow
// @connect      *
// @run-at       document-idle
// ==/UserScript==

// Adapted from the OverdriveUnspooler approach: hooks into the OverDrive BIF player's
// internal RequireJS module (audio-proxy-element) to intercept per-part MP3 URLs,
// then walks all book parts programmatically to trigger URL collection.
//
// Uses GM_download to save files directly to ~/Downloads, bypassing CORS and
// the browser's restriction on programmatic blob downloads from async code.
// Uses unsafeWindow to access requirejs/BIF page globals (required when @grant is used).

(function () {
    'use strict';

    const STORAGE_KEY = 'libby_dl_urls';

    // --- Utilities ---

    function waitFor(condition, timeout = 30000) {
        return new Promise((resolve, reject) => {
            if (condition()) return resolve();
            const interval = setInterval(() => {
                if (condition()) {
                    clearInterval(interval);
                    resolve();
                }
            }, 250);
            setTimeout(() => {
                clearInterval(interval);
                reject(new Error('Timeout waiting for condition'));
            }, timeout);
        });
    }

    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    function sanitizeFilename(s) {
        return s.replace(/[<>:"/\\|?*\x00-\x1f]/g, '_').trim();
    }

    function getBookTitle() {
        return unsafeWindow.document.title
            .replace(/\s*[|\-–]\s*(OverDrive|Libby).*$/i, '')
            .trim() || 'audiobook';
    }

    // --- URL Collection ---

    async function collectURLs() {
        unsafeWindow.sessionStorage.removeItem(STORAGE_KEY);
        const urls = [];

        try {
            await waitFor(() =>
                typeof unsafeWindow.requirejs !== 'undefined' &&
                typeof unsafeWindow.BIF !== 'undefined' &&
                unsafeWindow.BIF.objects &&
                unsafeWindow.BIF.objects.compass &&
                unsafeWindow.BIF.objects.spool
            );
        } catch (e) {
            throw new Error(
                'OverDrive player not ready. Make sure the audiobook is open and has started playing.'
            );
        }

        const AudioProxyElem = await new Promise((resolve, reject) => {
            unsafeWindow.requirejs(
                ['bifocal/themes/read/default/src/parts/audio-proxy-element'],
                resolve,
                (err) => reject(new Error('Failed to load audio-proxy-element: ' + err))
            );
        });

        const origSeek = AudioProxyElem.prototype.seek;

        AudioProxyElem.prototype.seek = function (t) {
            if (t && typeof t === 'string' && !urls.includes(t)) {
                urls.push(t);
            }
            return origSeek.apply(this, arguments);
        };

        const compass = unsafeWindow.BIF.objects.compass;
        const spool = unsafeWindow.BIF.objects.spool;
        let i = 0;
        while (true) {
            const part = compass.at(i);
            if (!part || part.bookMilliseconds === undefined) break;
            spool.seekWithinBook(part.bookMilliseconds);
            await sleep(300);
            i++;
        }

        AudioProxyElem.prototype.seek = origSeek;

        const unique = [...new Set(urls)];
        unsafeWindow.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(unique));
        console.log(`[Libby DL] Collected ${unique.length} URLs. First URL:`, unique[0]);
        return unique;
    }

    // --- Download ---

    // GM_download saves directly to ~/Downloads without CORS restrictions or
    // reliance on blob URLs + anchor clicks (which Chrome blocks from async code).
    function gmDownload(url, filename) {
        return new Promise((resolve, reject) => {
            GM_download({
                url: url,
                name: filename,
                saveAs: false,
                onload: () => resolve(),
                onerror: (err) => reject(new Error(`GM_download failed: ${JSON.stringify(err)}`)),
                ontimeout: () => reject(new Error('Download timed out: ' + filename)),
            });
        });
    }

    // Manifest is generated locally so we still use the blob approach for it
    function downloadBlob(content, filename) {
        const blob = new Blob([content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(() => URL.revokeObjectURL(url), 10000);
    }

    async function downloadAll(urls) {
        const title = getBookTitle();
        const safeTitle = sanitizeFilename(title);
        const padWidth = Math.max(3, String(urls.length).length);

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

        downloadBlob(manifest, 'libby_manifest.sh');
        await sleep(500);

        for (let i = 0; i < urls.length; i++) {
            try {
                await gmDownload(urls[i], filenames[i]);
                console.log(`[Libby DL] ${i + 1}/${urls.length}: ${filenames[i]}`);
                await sleep(300);
            } catch (err) {
                console.error(`[Libby DL] Failed to download part ${i + 1}:`, err);
            }
        }
    }

    // --- UI ---

    function addDownloadButton() {
        if (document.getElementById('libby-dl-btn')) return;

        const btn = document.createElement('button');
        btn.id = 'libby-dl-btn';
        btn.title = 'Download Audiobook';
        btn.textContent = '⬇';
        Object.assign(btn.style, {
            position: 'fixed',
            top: '10px',
            right: '10px',
            zIndex: '99999',
            background: '#1d65a6',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            padding: '8px 14px',
            fontSize: '20px',
            cursor: 'pointer',
            boxShadow: '0 2px 8px rgba(0,0,0,0.35)',
            fontFamily: 'sans-serif',
            lineHeight: '1',
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
                let urls = JSON.parse(unsafeWindow.sessionStorage.getItem(STORAGE_KEY) || '[]');

                if (urls.length === 0) {
                    btn.title = 'Collecting audio URLs…';
                    urls = await collectURLs();
                }

                if (urls.length === 0) {
                    alert('[Libby DL] No audio URLs found. Try playing the book for a moment first.');
                    return;
                }

                btn.textContent = '⬇';
                btn.title = `Downloading ${urls.length} parts…`;
                btn.style.background = '#2a8a2a';

                await downloadAll(urls);

                btn.textContent = '✓';
                btn.title = `Done: ${urls.length} parts + libby_manifest.sh → run libby_get in terminal`;
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

        // Re-append if the SPA re-renders and removes the button
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
