# New Machine Setup

A checklist for setting up a fresh Ubuntu/Linux installation with the MATE desktop environment.

## Contents

- **`steps`** -- A plain-text checklist covering:
  - MATE desktop installation and configuration
  - System settings (sound, mouse, keyboard, power)
  - Application installation (Firefox, Pulsar editor, Telegram, Signal, GIMP, VLC, Guake, LibreOffice, Chromium, Slack, Discord, Conda, Cursor, FreeCAD, Bitwarden, Zoom, Okular, Emacs, darktable, FreeTube, Xournal, Spotify, xclip, fzf)
  - GitHub CLI setup and multi-account configuration

## Usage

Open the `steps` file and work through the checklist. Items are marked with `[x]` when complete and `[]` when still pending.

## macOS

Run `../../install.sh --deps` from the repo root (see the top-level README). It wires `bashrc_aliases` into `~/.zshrc` and installs the optional tools with Homebrew (`brew install fzf bat jq exiftool yt-dlp mpv sox gh`). Nothing else in `steps` is needed on a Mac.
