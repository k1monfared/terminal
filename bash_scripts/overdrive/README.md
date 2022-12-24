# OverDrive (forked from https://chbrown.github.io/overdrive)

OverDrive is great and distributes DRM-free MP3s instead of some fragile DRM-ridden format, which is awesome.
Way to go, Rakuten / OverDrive, fight the man!

Their "OverDrive Media Console" application for macOS is pretty simple,
but I like to automate things,
so I wrote a bash script, [`overdrive.sh`](overdrive.sh),
which takes one or more `.odm` files,
and downloads the audio content files locally, just like the app.

Then they stopped supporting macOS altogether after Mojave (10.14),
leaving Catalina (10.15), Big Sur (11), and Monterey (12) users with no choice but to find a third-party option,
such as this script 😉

Btw, it works on Linux too!


## Instructions

First, install the script and make it executable:

```sh
mkdir -p ~/.local/bin
curl https://chbrown.github.io/overdrive/overdrive.sh -o ~/.local/bin/overdrive
chmod +x ~/.local/bin/overdrive
```

(You only need to do that ☝️ step once!
It is also idempotent — you can run it multiple times no problem.)

Now download an OverDrive loan file from your library or wherever.
I'll assume that yours is called `Novel.odm`.
Assuming you've downloaded it to your `~/Downloads` folder, simply run the following command:

```sh
cd ~/Downloads
~/.local/bin/overdrive download Novel.odm
```

This will display a couple dozen lines as it downloads the book,
most of which are only relevant/useful if something goes wrong.

Assuming that you decided to listen to Blake Crouch's _Recursion_,
once the script finishes you will have a new folder called `Blake Crouch - Recursion` (inside your "Downloads" folder),
inside which will be several MP3s: `Part01.mp3`, `Part02.mp3`, _etc._
(these "parts" don't necessarily correspond to actual chapters in the book;
there may be multiple chapters in a single part, or a single chapter spread out over multiple parts),
and the cover art: `folder.jpg`.

And that's it, you're done! 🎉

The rest of this README describes
[how to debug various issues](#debugging) people run into
and [some automation tips](#advanced);
if your book downloaded just fine, you don't need to worry about any of that 😁


## Debugging

If you have trouble getting the script to run successfully, add the `--verbose` flag and retry, e.g.:

```sh
~/.local/bin/overdrive download Novel.odm --verbose
```

This will call `set -x` to turn bash's `xtrace` option on,
which causes a trace of all commands to be printed to standard error,
prefixed with one or more `+` signs.
It will also set all `curl` calls to not be silent.

### Common errors

If you get an error message like `-bash: ~/.local/bin/overdrive: Permission denied` or `zsh: permission denied: overdrive`,
you installed `overdrive` to the right place 👍, but didn't set the executable flag 😟.
Try running the `chmod +x` command from the [Instructions](#instructions).

---

If you see a line that reads `I/O error : Operation not permitted`,
you probably didn't [allow Terminal / iTerm2 to access your Downloads folder](https://www.google.com/search?q=allow+terminal+access+downloads+folder+macos).

---

If calling the script with any combination of options produces an error message like
```console
.local/bin/overdrive: line 1: syntax error near unexpected token `newline'
.local/bin/overdrive: line 1: `<!DOCTYPE html>'
```
this indicates you installed the script incorrectly.
You most likely saved the GitHub webpage that displays the source code, instead of just the source code.
To fix, follow the [Instructions](#instructions) _exactly_ as shown.

If you are security conscious 🧐 (good for you!), feel free to `cat -n ~/.local/bin/overdrive` after installing, but before executing the script for the first time.

---

If the script fails right after a `curl` call, and then you rerun it with `--verbose` and get an error message like `curl: (60) SSL certificate problem: certificate has expired`,
that indicates the OverDrive server cannot be verified from your system's certificate authority.
You can bypass the security check by adding `--insecure` when calling the `overdrive` script.

---

If your library doesn't show you the link to "Download MP3 audiobook" (i.e., the `.odm` file),
the easiest way to get it to (re)appear is to pretend to use an OS that they do support —
by editing the "User Agent" that your browser presents itself as.
Simply install a Chrome or Firefox extension to customize your user agent,
then select some Windows or pre-Catalina value from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/ (or wherever), and refresh your "Loans" page.

**New** (as of 2022-02):
you must now also click the "Do you have the OverDrive app? >" disclosure/dropdown
to get the "Download MP3 audiobook" link to show up.

---

I call this a "standalone" script,
but it actually depends on several executables being available on your `PATH`:

* `curl`
* `uuidgen`
* `xmllint`
* `iconv`
* `openssl`
* `base64`

If you get an error like `-bash: xmllint: command not found`,
you're evidently missing one of those;
the following package manager one-liners should help:

| Command | OS |
|:--------|:---|
| _N/A_<sup>†</sup> | # macOS
| `apt-get install curl uuid-runtime libxml2-utils libc-bin openssl coreutils` | # Debian / Ubuntu
| `apk add bash curl util-linux libxml2-utils openssl` | # Alpine
| `pacman -S curl util-linux libxml2 openssl coreutils` | # Arch
| `dnf install curl glibc-common util-linux libxml2 openssl coreutils` | # Fedora
| (_please create a [PR](https://github.com/chbrown/overdrive/pulls) to contribute a new OS!_)

<sup>†</sup>All required commands are installed by default on macOS 10.14 (Mojave), 10.15 (Catalina), 12.6 (Monterey),
and probably everywhere in between — those are just the versions I've personally tested.
It also works with the latest version of OpenSSL,
so if you want, `brew install openssl`.

---

If none of that solves your problem,
you can [open an issue](https://github.com/chbrown/overdrive/issues/new),
including the full debug output (optimally as a [gist](https://gist.github.com/)),
and I'll try to help you out.

* If you email me asking for technical help with this script (or any of my GitHub projects),
  I will redirect you to create a GitHub issue.
  Don't have an account? [Create one](https://github.com/signup), they're free. \
  Sure I could help you over email, but then the solution would be siloed away in our inboxes;
  by corresponding in an issue, other users will be able to find it.
* You _can_ email me cute little thank you notes; those are always fun to read 😀


## Advanced

### `PATH`

All the basic examples above invoke the script using its full path,
(hopefully) to avoid `PATH`-related headaches for new users.
<!-- Seriously, I feel like half the time I've spent answering issues is trying to mindread what they've done to their PATH and the most likely way to fix it. -->
But if installed as [instructed](#instructions),
you should be able to call just `overdrive [...]` instead of `~/.local/bin/overdrive [...]`,
since `~/.local/bin` is commonly used for tools like this,
and many default init scripts automatically add it to your `PATH` if it exists.

However, if calling `overdrive` produces the error message `-bash: overdrive: command not found`,
you'll can easily add `~/.local/bin` to your `PATH`. One way to do this:

```sh
printf 'export PATH=$HOME/.local/bin:$PATH\n' >> ~/.bashrc
source ~/.bashrc
```

Or if you're using `zsh` instead of `bash`, run this instead:

```sh
printf 'export PATH=$HOME/.local/bin:$PATH\n' >> ~/.zshrc
source ~/.zshrc
```

### Early Return

Early return is entirely optional,
and AFAICT, equivalent to clicking "Return" on the library's OverDrive website,
but if you want, you can "return" a loan using this script, e.g.:

    overdrive return Novel.odm


## License

Copyright © 2017–2021 Christopher Brown.
[MIT Licensed](https://chbrown.github.io/licenses/MIT/#2017-2021).
