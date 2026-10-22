# lib/platform.sh - one place for every Linux/macOS difference.
# POSIX-sh compatible: source it from bash, zsh, or any script.
#   . "$(dirname "$0")/lib/platform.sh"
# Scripts call the helpers below instead of xclip / xdg-open / firefox / apt ...

case "$(uname -s)" in
    Darwin) OS_KIND=mac ;;
    Linux)  OS_KIND=linux ;;
    *)      OS_KIND=other ;;
esac
export OS_KIND

have() { command -v "$1" >/dev/null 2>&1; }

# require_os linux|mac [what]: bail out of a script that only makes sense on one OS
require_os() {
    [ "$OS_KIND" = "$1" ] && return 0
    echo "${2:-this command} only works on $1 (you are on $OS_KIND)." >&2
    exit 1
}

# ---- defaults for the per-user folders normally set in bashrc.private ----
: "${drafts_folder:=$HOME/drafts}"
: "${memory_address:=$drafts_folder/memory}"
: "${public_notes_folder:=$HOME/public/notes}"
: "${private_notes_folder:=$HOME/private_notes}"
: "${audiobooks_folder:=$HOME/audiobooks/}"
: "${blog_folder:=$HOME/blog}"
: "${EDITOR:=code}"

# ---- where removable media shows up ----
if [ "$OS_KIND" = mac ]; then MEDIA_ROOT=/Volumes; else MEDIA_ROOT="/media/$USER"; fi

# ---- clipboard ----
# clip_copy: stdin -> clipboard      clip_paste: clipboard -> stdout
clip_copy() {
    if   have pbcopy;   then pbcopy
    elif have wl-copy;  then wl-copy
    elif have xclip;    then xclip -selection clipboard
    elif have xsel;     then xsel --clipboard --input
    else echo "no clipboard tool (install xclip or wl-clipboard)" >&2; return 1; fi
}
clip_paste() {
    if   have pbpaste;  then pbpaste
    elif have wl-paste; then wl-paste
    elif have xclip;    then xclip -selection clipboard -o
    elif have xsel;     then xsel --clipboard --output
    else echo "no clipboard tool (install xclip or wl-clipboard)" >&2; return 1; fi
}

# ---- opening things ----
# open_path: open a file/URL with the default app
open_path() { if have open; then open "$@"; else xdg-open "$@" >/dev/null 2>&1; fi; }
# browser URL: Firefox if present, otherwise the default browser
browser() {
    if   have firefox;                         then firefox "$@" >/dev/null 2>&1 &
    elif [ -d /Applications/Firefox.app ];     then open -a Firefox "$@"
    else open_path "$@"; fi
}

# ---- editor ----
# edit_wait FILE: open in $EDITOR and block until closed (for gui editors that return at once)
edit_wait() {
    case "$EDITOR" in
        code|code-insiders|cursor|subl|atom|pulsar) $EDITOR --wait "$@" ;;
        *) $EDITOR "$@" ;;
    esac
}

# ---- desktop notification ----
notify_desktop() {
    if have notify-send; then notify-send "$1" "$2"
    elif have osascript; then osascript -e "display notification \"$2\" with title \"$1\""
    else echo "$1: $2"; fi
}

# ---- bat is `batcat` on Debian/Ubuntu ----
if   have bat;    then BAT_CMD=bat
elif have batcat; then BAT_CMD=batcat
else BAT_CMD=; fi
export BAT_CMD

# ---- media player (first one found) ----
play_media() {
    if   have mpv;     then mpv "$@"
    elif have mplayer; then mplayer "$@"
    elif have vlc;     then vlc "$@"
    else open_path "$@"; fi
}

# ---- tiny portability shims ----
# timestamp in ISO-8601 (BSD date has no -I)
date_iso() { date +%Y-%m-%dT%H:%M:%S%z; }
# sed -i that works with both GNU and BSD sed
sed_inplace() { if [ "$OS_KIND" = mac ]; then sed -i '' "$@"; else sed -i "$@"; fi; }
# realpath exists on macOS 13+, fall back for older ones
if ! have realpath; then realpath() { (cd "$(dirname "$1")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "$1")"); }; fi
