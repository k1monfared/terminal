# bash_scripts

Bash scripts and shell aliases used on a daily basis. Source `bashrc_aliases` from your `~/.bashrc` to activate everything.

## Quick start

```bash
bashscripts="/home/$USER/bash_scripts"
source "$bashscripts/bashrc_aliases"
export PATH="$PATH:$bashscripts"
```

## bashrc_aliases

The central configuration file. It defines aliases, shell functions, and environment variables that tie all the scripts together.

### Editing the aliases file

| Alias | Action |
|-------|--------|
| `aliases_edit` | Open `bashrc_aliases` in your editor |
| `aliases_list` | Print all aliases to the terminal |

### System

| Alias / Function | Action |
|------------------|--------|
| `hib` | Hibernate the system |
| `bat` | Shortcut for `batcat` |

### Shortcuts

| Alias | Script | Action |
|-------|--------|--------|
| `search` | `duckduckgo.sh` | Search DuckDuckGo in Firefox |
| `contacts` | `contacts.sh` | Search Google Contacts in Firefox |
| `mic` | `record.sh` | Record audio from the microphone (requires `sox`) |
| `organize` | `organize_photos_monthly_this_folder.sh` | Organize photos in the current folder into YYYY-MM subfolders |
| `jnb` | -- | Start Jupyter Notebook |
| `cb` | `copy_file_to_clipboard.sh` | Copy a file's contents to clipboard |

### todo.txt

| Alias | Action |
|-------|--------|
| `t` | Run todo.txt CLI |

### APT package management

| Alias | Action |
|-------|--------|
| `ins` | `sudo apt install` |
| `upd` | `sudo apt update` |
| `upg` | `sudo apt upgrade -y` |
| `remove` | `sudo apt remove` |
| `upg-secure` | `sudo unattended-upgrade` |

### Notes

| Alias / Function | Script | Action |
|------------------|--------|--------|
| `note` | `note.sh` | Create a new note file (timestamped) and open in editor |
| `n` | `quicknote.sh` | Write a quick one-liner note to a file |
| `ln` | `lastnote.sh` | Open the most recent note |
| `notes` | `search_notes()` | Search through public, private, or draft notes using fzf |
| `blog` | `blog.sh` | Create a new blog post file (date-stamped) and open in editor |
| `pn <file>` | -- | Open a public note by name |
| `pvn <file>` | -- | Open a private note by name |

### GitHub

| Alias / Function | Script | Action |
|------------------|--------|--------|
| `git_switch` | `git_switch.sh` | Switch git user config between accounts |
| `git_who` | -- | Print the currently active git account |
| `git_init` | -- | Initialize a repo, make initial commit, create private GitHub repo |
| `git_push_all [msg]` | -- | Stage all, commit with message (or "quick commit"), and push |
| `git_activate <name>` | -- | Set the active git account name |
| `git_clone <account> <link>` | -- | Clone a repo using a specific SSH identity |

### GitHub Gist

| Alias | Script | Action |
|-------|--------|--------|
| `gist` | `gist.sh` | Create a new private gist (opens editor first) |
| `gistp` | `publicgist.sh` | Create a new public gist (opens editor first) |
| `gg` | `quickgist.sh` | Quickly publish text as a gist from the command line |

### VPN

| Alias | Action |
|-------|--------|
| `ppn` | Run Proton VPN CLI |

### Terminal helpers

| Alias / Function | Action |
|------------------|--------|
| `cap` | Pipe output through `tee` to save it to `/tmp/capture.out` |
| `ret` | Retrieve the last captured output |

### Passwords

| Alias / Function | Action |
|------------------|--------|
| `bw` | Run Bitwarden CLI |
| `bwc` | Copy password from Bitwarden using fzf selection |
| `bwu` | Unlock Bitwarden session |
| `bwl` | Lock Bitwarden session |
| `enc <file>` | Encrypt a file with AES-256 using GPG |
| `dec <file>` | Decrypt a GPG-encrypted file |

### Search

| Alias / Function | Action |
|------------------|--------|
| `search_text [dir]` | Full-text search across text files using fzf with bat preview |
| `fz` | Find files in current directory with fzf preview |
| `fza` | Find files system-wide with fzf preview |

### Memory (clipboard journal)

| Alias / Function | Script | Action |
|------------------|--------|--------|
| `mem` | `memory.sh` | Save clipboard contents to a date-organized memory file |
| `remem` | -- | Search through saved memories using fzf |

### Utilities

| Alias / Function | Action |
|------------------|--------|
| `notify` | Send a desktop notification |
| `plotbills` | Plot bills data |
| `vnc` | Run VNC manager |
| `new_project` | Interactive project creation: mkdir, git init, GitHub repo, optional template |
| `use-poe` | Switch Claude Code to use Poe API |
| `use-claude-api` | Switch Claude Code to use Claude API key |
| `use-claude` | Switch to default Claude Code auth |
| `check-claude-config` | Print current AI API configuration |

### Library (audiobooks)

| Alias / Function | Action |
|------------------|--------|
| `libby_get` | Move downloaded Libby audiobook files into organized folder (uses manifest from browser userscript) |

See [libby/README.md](libby/README.md) for the browser userscript that captures audiobook MP3s.

---

## Standalone scripts

### Photo organization

- **`organize_photos_monthly_this_folder.sh`** -- Organizes all image files in the current directory into `YYYY-MM` subfolders based on EXIF creation date. Uses `get_image_creation_yymm`.
- **`organize_photos_monthly.sh`** / **`organize_photos_monthly.py`** -- Python-based photo organizer using Pillow. Handles associated raw files (`.CR3`, `.CR3.xmp`).
- **`copy_canon.sh`** -- Copy photos from a Canon camera SD card, optionally delete originals, then organize into monthly folders.
- **`get_image_creation_datetime`** -- Extract full creation datetime from image EXIF (requires `exiftool`).
- **`get_image_creation_yymm`** -- Extract `YYYY-MM` from image EXIF data.
- **`get_image_creation_yymmdd`** -- Extract `YYYY-MM-DD` from image EXIF data.

### Phone backup

- **`emptyphone.sh`** -- Move files from an Android phone (connected via MTP/gvfs) to a dated backup folder on the computer.
- **`phone_places_move.lst`** -- List of phone directories whose contents should be moved.
- **`phone_places_copy.lst`** -- List of phone directories whose contents should be copied.
- **`phone_places_delete.lst`** -- List of phone directories whose contents should be deleted.

### System utilities

- **`brightness.sh`** -- Increase or decrease screen brightness via sysfs (`/sys/class/backlight/intel_backlight/brightness`).
- **`rotate.sh`** -- Toggle screen rotation between normal and inverted (for Wacom tablet laptops). Handles stylus, eraser, touchpad, and trackpoint rotation.
- **`record.sh`** -- Record audio from the microphone to a timestamped WAV file (requires `sox`).
- **`copy_file_to_clipboard.sh`** -- Copy a file's contents to the X clipboard (requires `xclip`).
- **`get_public_ip`** -- Display public IPv4, IPv6, and geolocation info.

### Notes and memory

- **`note.sh`** -- Create a timestamped note file in the drafts folder and open it in the editor.
- **`quicknote.sh`** -- Append a quick one-liner note to a timestamped file.
- **`lastnote.sh`** -- Open the most recently created note.
- **`blog.sh`** -- Create a date-stamped blog post file and open it in the editor.
- **`memory.sh`** -- Save clipboard contents to a date-organized memory file (uses `xclip`).
- **`remem`** -- Display the last saved memory entry.

### Git utilities

- **`git_switch.sh`** -- Switch local git config (user.email and user.name) between multiple GitHub accounts.

### Gist helpers

- **`gist.sh`** -- Create a private GitHub gist: opens a text editor, then publishes the file.
- **`publicgist.sh`** -- Same as `gist.sh` but creates a public gist.
- **`quickgist.sh`** -- Publish text directly as a gist from command-line arguments.

### Web search

- **`duckduckgo.sh`** -- Open a DuckDuckGo search in Firefox.
- **`contacts.sh`** -- Open a Google Contacts search in Firefox.

### Bitwarden

- **`bwc`** -- Interactive Bitwarden password copier using `jq` and `fzf`. Copies username first, then password on keypress.

---

## Subfolders

| Folder | Description |
|--------|-------------|
| [terminal_youtube_player/](terminal_youtube_player/) | Download and play YouTube videos from the terminal |
| [rip_audio_cd/](rip_audio_cd/) | Rip audio CDs to MP3 |
| [libby/](libby/) | Libby/OverDrive audiobook downloader (browser userscript) |
| [new_machine_setup/](new_machine_setup/) | Checklist for setting up a new Linux machine |
| [deprecated/overdrive/](deprecated/overdrive/) | (Deprecated) ODM-based OverDrive downloader |

## Private configuration

The file `bashrc.private` (git-ignored via `*.private` in `.gitignore`) should define:

```bash
export audiobooks_folder="$HOME/books/audiobook/"
export git_username="your_username"
export private_notes_folder="$HOME/Documents/notes"
export public_notes_folder="$HOME/public/notes"
export memory_address="$private_notes_folder/memory"
export drafts_folder="$HOME/Documents/drafts"
export blog_folder="$HOME/public/notes/blog/"
```

## License

GPL v3 -- see [LICENSE](LICENSE).
