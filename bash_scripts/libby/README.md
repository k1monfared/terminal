# Libby Audiobook Downloader

Downloads audiobook MP3s from the OverDrive web player (replaces the old `.odm` workflow removed in February 2025).

## Setup (one-time)

1. Install the [Tampermonkey](https://www.tampermonkey.net/) browser extension
2. Click the Tampermonkey icon in the toolbar → **Dashboard**
3. Click the **+** tab to create a new script
4. Paste the contents of `libby_downloader.user.js` → **Ctrl+S** to save

## Usage

1. Go to `app.overdrive.com` or `libbyapp.com`, check out an audiobook
2. Click **Listen in browser** — this opens `*.listen.overdrive.com`
3. Wait a moment for the player to load, then click the **⬇** button in the top-right corner
   1. this will take a while before it shows up, be patient. 
4. All MP3 parts and a `libby_manifest.sh` file download to `~/Downloads`
5. In the terminal, run:
   ```
   libby_get
   ```
   Enter the author name when prompted (or press Enter to leave blank). Files are moved to `$audiobooks_folder/Author - Title/`.

## How it works

- Only activates on `*.listen.overdrive.com` — nowhere else.
- On page load, injects a single ⬇ button. Nothing else runs until you click it.
- On click, it loads the player's own internal `audio-proxy-element` module via RequireJS and temporarily patches its `seek()` method to record the MP3 URL passed to it each time. It then walks every book part by calling `spool.seekWithinBook()` for each entry, which fires the patched seek and captures the URL. The original `seek()` is always restored when done.
- The manifest file (`libby_manifest.sh`) is generated entirely in-memory — no network request. Each MP3 is fetched from OverDrive's own CDN (the same URLs the player streams from) and saved via a browser download.
- No data is sent anywhere. The only network activity is fetching MP3s from OverDrive, which you're already authenticated to.
- Collected URLs are stored in `sessionStorage` only (cleared when the tab closes).

**Note:** While collecting, the player's seek position jumps through every part of the book — you'll see/hear it skipping around for a few seconds per part. This is expected.

## Permissions and security (v1.1+)

The script uses two Tampermonkey grants that are worth understanding:

**`GM_xmlhttpRequest` + `@connect *`**
The browser's normal `fetch()` is blocked by CORS when the MP3 CDN domain differs from `listen.overdrive.com`. `GM_xmlhttpRequest` is Tampermonkey's background HTTP requester — it bypasses CORS because it runs outside the page's security context. `@connect *` allows it to connect to any host, since OverDrive uses multiple CDN domains that vary by library.

The security implication is that this script *could* make HTTP requests to arbitrary domains if the code were malicious. It doesn't — the only URLs passed to `GM_xmlhttpRequest` are the ones captured from the OverDrive player itself. But you are trusting this script not to exfiltrate data, the same as any other userscript with this grant.

**`unsafeWindow`**
When any `@grant` is used, Tampermonkey sandboxes the script and page globals like `requirejs` and `BIF` are no longer directly accessible. `unsafeWindow` is a reference to the real page `window`, used here only to read `requirejs`, `BIF`, `sessionStorage`, and `document.title`. It is not used to modify page behaviour beyond the temporary `seek()` patch during collection.

**Mitigation:** The script is short and self-contained — read it before installing. Never install userscripts from untrusted sources, especially ones with `GM_xmlhttpRequest` + `@connect *`.
