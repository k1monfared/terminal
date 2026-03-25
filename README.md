# Terminal

A collection of bash scripts, shell utilities, and LaTeX tools for everyday use on Linux.

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

## Setup

```bash
# In your ~/.bashrc, add:
bashscripts="/home/$USER/bash_scripts"   # or wherever you cloned this
source "$bashscripts/bashrc_aliases"
export PATH="$PATH:$bashscripts"
```

The `bashrc.private` file (git-ignored) holds personal paths and API keys. Create your own with exports like `audiobooks_folder`, `memory_address`, `drafts_folder`, etc.

## License

GPL v3 -- see [LICENSE](bash_scripts/LICENSE).
