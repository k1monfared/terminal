#!/bin/bash

# Directory to search
SEARCH_DIR="$HOME/Documents/drafts"
CONTEXT_LINES=10

# Use find to locate all text files and cat to send their contents to fzf
# We prepend each line with its filename and line number
find "$SEARCH_DIR" -type f -name '*' -exec awk '{print FILENAME ":" FNR ":" $0}' {} + | \
fzf --ansi --delimiter ':' \
    --color fg:242,bg:16,hl:108,fg+:15,bg+:236,hl+:168 \
    --color info:148,prompt:110,spinner:148,pointer:168,marker:168 \
    --preview 'batcat --decorations=always --style=numbers --color=always --highlight-line {2} {1}' \
    --preview-window wrap | \
awk -F ':' '{print $1 ":" $2 " " $3}'
