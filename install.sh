#!/usr/bin/env bash
# install.sh - wire this repo into your shell on Linux or macOS.
#   ./install.sh               add the source line to ~/.bashrc and/or ~/.zshrc, create bashrc.private
#   ./install.sh --deps        also install the optional tools (apt or brew)
# Safe to re-run.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
BS="$HERE/bash_scripts"
. "$BS/lib/platform.sh"

LINE="source \"$BS/bashrc_aliases\""
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    # only touch the rc of shells that are installed / in use: zsh on mac, bash on linux, plus any rc that exists
    case "$rc" in
        *.zshrc)  [ "$OS_KIND" = mac ] || [ -f "$rc" ] || continue ;;
        *.bashrc) [ "$OS_KIND" = linux ] || [ -f "$rc" ] || continue ;;
    esac
    if grep -Fqs "$BS/bashrc_aliases" "$rc" 2>/dev/null; then
        echo "already wired: $rc"
    else
        printf '\n# terminal scripts (%s)\n%s\n' "$HERE" "$LINE" >> "$rc"
        echo "added to $rc"
    fi
done

if [ ! -f "$BS/bashrc.private" ]; then
    cp "$BS/bashrc.private.example" "$BS/bashrc.private"
    echo "created $BS/bashrc.private (edit it if you want non-default folders)"
fi

# ---- optional tools ----
# name:apt-package:brew-package  (a tool is skipped silently if already present)
TOOLS="fzf:fzf:fzf  bat:bat:bat  jq:jq:jq  exiftool:libimage-exiftool-perl:exiftool  yt-dlp:yt-dlp:yt-dlp  mpv:mpv:mpv  sox:sox:sox  gh:gh:gh"
missing_apt=""; missing_brew=""; missing_names=""
for t in $TOOLS; do
    name="${t%%:*}"; rest="${t#*:}"; apt_pkg="${rest%%:*}"; brew_pkg="${rest#*:}"
    have "$name" && continue
    [ "$name" = bat ] && have batcat && continue
    missing_names="$missing_names $name"; missing_apt="$missing_apt $apt_pkg"; missing_brew="$missing_brew $brew_pkg"
done
[ "$OS_KIND" = linux ] && ! have xclip && ! have wl-copy && { missing_names="$missing_names xclip"; missing_apt="$missing_apt xclip"; }

if [ -z "$missing_names" ]; then
    echo "all optional tools present"
else
    if   have brew; then cmd="brew install$missing_brew"
    elif have apt;  then cmd="sudo apt install$missing_apt"
    else cmd=""; fi
    echo "optional tools missing:$missing_names"
    if [ "${1:-}" = "--deps" ] && [ -n "$cmd" ]; then echo "+ $cmd"; $cmd
    elif [ -n "$cmd" ]; then echo "  install them with:  $cmd   (or re-run with --deps)"; fi
fi
echo "done. Open a new terminal, then try: cheat"
