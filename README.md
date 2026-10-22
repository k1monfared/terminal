# Terminal

A collection of bash scripts, shell utilities, and LaTeX tools for everyday use on Linux (Ubuntu MATE etc.) and macOS.

## Overview

This repository contains personal shell scripts and configurations organized into the following areas:

### [bash_scripts/](bash_scripts/)

The main collection of scripts and shell aliases. Source `bashrc_aliases` from your `~/.bashrc` to get access to all shortcuts. See the [bash_scripts README](bash_scripts/README.md) for full details.

**Highlights:**

| Category | Scripts | Description |
|----------|---------|-------------|
| Shell config | `bashrc_aliases`, `bashrc.private` | Aliases, functions, and environment variables |
| Notes | `note.sh`, `quicknote.sh`, `lastnote.sh`, `blog.sh` | Quick note-taking and retrieval from the terminal |
| Memory | `memory.sh`, `remem` | Save clipboard contents organized by date, search later with fzf |
| GitHub | `git_switch.sh`, `gist.sh`, `publicgist.sh`, `quickgist.sh` | Git account switching and quick gist creation |
| Photos | `organize_photos_monthly*.sh/.py`, `get_image_creation_*`, `copy_canon.sh` | Organize photos into YYYY-MM folders by EXIF date |
| Phone | `emptyphone.sh`, `phone_places_*.lst` | Back up and clean files from an Android phone over MTP |
| Search | `duckduckgo.sh`, `contacts.sh` | Open DuckDuckGo or Google Contacts searches in Firefox |
| System | `brightness.sh`, `rotate.sh`, `record.sh`, `copy_file_to_clipboard.sh` | Screen brightness, display rotation, voice recording, clipboard |
| Passwords | `bwc` | Bitwarden CLI helper with fzf selection |
| Networking | `get_public_ip` | Show public IPv4/IPv6 and geolocation |
| New machine | `new_machine_setup/steps` | Checklist for setting up a fresh Linux install |

### Subprojects

| Folder | Description |
|--------|-------------|
| [bash_scripts/terminal_youtube_player/](bash_scripts/terminal_youtube_player/) | Download and play YouTube videos from the terminal using mplayer |
| [bash_scripts/rip_audio_cd/](bash_scripts/rip_audio_cd/) | Rip audio CDs to MP3 using cdparanoia and lame |
| [bash_scripts/libby/](bash_scripts/libby/) | Browser userscript to download Libby/OverDrive audiobooks as MP3s |
| [bash_scripts/deprecated/overdrive/](bash_scripts/deprecated/overdrive/) | (Deprecated) ODM-based OverDrive audiobook downloader |

### [latex/](latex/)

| Folder | Description |
|--------|-------------|
| [latex/animate_pdf/](latex/animate_pdf/) | Embed GIF animations in PDF files using LaTeX and the `animate` package |

## Setup (Linux or macOS)

```bash
git clone https://github.com/k1monfared/terminal ~/public/terminal
~/public/terminal/install.sh          # adds one `source` line to ~/.bashrc / ~/.zshrc
~/public/terminal/install.sh --deps   # optional: also install fzf, bat, jq, exiftool, yt-dlp, ... via apt/brew
```

Works in bash and zsh. Open a new terminal and run `cheat` to see every command available on this machine.

### How the two systems share code

| Where | What |
|-------|------|
| `bash_scripts/lib/platform.sh` | The only place that knows about OS differences: `clip_copy`/`clip_paste` (pbcopy / xclip / wl-copy), `open_path`, `browser`, `notify_desktop`, `play_media`, `edit_wait`, `date_iso`, `sed_inplace`, `MEDIA_ROOT`, `BAT_CMD`, plus defaults for the folders in `bashrc.private`. Every script sources it instead of calling `xclip`, `firefox`, `/home/$USER`, ... directly. |
| `bash_scripts/platform/linux.sh` | Linux only: hibernate, GNOME remote desktop, ibus, `rotate`, `brightness`, `procmon`. |
| `bash_scripts/platform/mac.sh` | macOS only: sleep/lock shortcuts. |
| `bash_scripts/platform/apt.sh`, `brew.sh` | The same `ins upd upg remove` aliases on either package manager. |
| `bash_scripts/drives.sh` | One `eject` front-end; `lsblk/udisks` backend on Linux, `diskutil` backend on macOS. `fix_mount` (NTFS) is Linux only. |

The cheatsheet (`cheat`) hides entries that do not exist on the current machine, so Linux-only commands simply do not appear on a Mac. Scripts that are inherently Linux (`emptyphone.sh`, `rotate.sh`, `brightness.sh`, `procmon.sh`) are only wired up on Linux.

To add something OS-specific: put the helper in `lib/platform.sh` (if scripts need it) or the alias in `platform/<os>.sh`; do not add `if uname` checks elsewhere.

Personal settings live in `bash_scripts/bashrc.private` (git-ignored); see `bashrc.private.example`.

## License

GPL v3 -- see [LICENSE](bash_scripts/LICENSE).
