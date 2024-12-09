#!/bin/bash

# Variables
EDITOR="${EDITOR:-nano}"                            # Default editor
CLIPBOARD_CMD="xclip -selection clipboard"          # Change to pbcopy for macOS
LOG_FILE="/tmp/fzf_script.log"                      # Log file path

# Color Definitions Using tput
COLOR_BLUE=$(tput setaf 4)
COLOR_GREEN=$(tput setaf 2)
COLOR_RED=$(tput setaf 1)
COLOR_RESET=$(tput sgr0)

# Logging function
log_action() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Error handling
handle_error() {
    echo -e "${COLOR_RED}Error: $1${COLOR_RESET}" >&2
    log_action "Error: $1"
}

# Colorized menu header
print_header() {
    echo -e "${COLOR_GREEN}FZF Bash Utility${COLOR_RESET}"
}

# Display help
show_help() {
    print_header
    cat <<EOF
Options:
  ${COLOR_BLUE}1${COLOR_RESET}  Search files in current directory and subdirectories
  ${COLOR_BLUE}2${COLOR_RESET}  Search files on the entire system
  ${COLOR_BLUE}3${COLOR_RESET}  Search for text in files (recursive)
  ${COLOR_BLUE}4${COLOR_RESET}  Search recently modified files
  ${COLOR_BLUE}5${COLOR_RESET}  Include hidden files in search
  ${COLOR_BLUE}6${COLOR_RESET}  Search files by type
  ${COLOR_BLUE}7${COLOR_RESET}  Find large files
  ${COLOR_BLUE}8${COLOR_RESET}  Interact with Git repositories
  ${COLOR_BLUE}9${COLOR_RESET}  Search process list
  ${COLOR_BLUE}0${COLOR_RESET}  Exit
EOF
}


# Functions for each feature
search_current_directory() {
    find . -type f 2>/dev/null | fzf --preview 'head -n 100 {}'
}

search_entire_system() {
    sudo find / -type f 2>/dev/null | fzf --preview 'head -n 100 {}'
}

search_text_in_files() {
    SEARCH_DIR="."
    
    # Use find to locate all text files and cat to send their contents to fzf
    # We prepend each line with its filename and line number
    find "$SEARCH_DIR" -type f -name '*' -exec awk '{print FILENAME ":" FNR ":" $0}' {} + | \
    fzf --ansi --delimiter ':' \
        --color fg:242,bg:16,hl:108,fg+:15,bg+:236,hl+:168 \
        --color info:148,prompt:110,spinner:148,pointer:168,marker:168 \
        --preview '[[ $(command -v bat) ]] && bat --style=numbers --color=always --highlight-line {2} {1} || less +{2} {1}' \
        --preview-window=right:60%:wrap \
        --bind 'enter:execute-silent([[ $(command -v bat) ]] && bat --style=numbers --color=always --highlight-line {2} {1} || less +{2} {1})' | \
    awk -F ':' '{print $1 ":" $2}'
}

search_recent_files() {
    find . -type f -mtime -7 2>/dev/null | fzf --preview 'ls -lh {}'
}

search_hidden_files() {
    find . -type f -name ".*" 2>/dev/null | fzf --preview 'head -n 100 {}'
}

preview_file_contents() {
    find . -type f 2>/dev/null | fzf --preview 'cat {}'
}

search_by_file_type() {
    read -rp "Enter file extension (e.g., txt, jpg): " ext
    [[ -z "$ext" ]] && handle_error "File extension cannot be empty" && return
    find . -type f -name "*.$ext" 2>/dev/null | fzf --preview 'head -n 100 {}'
}

find_large_files() {
    find . -type f -size +100M 2>/dev/null | fzf --preview 'ls -lh {}'
}

interact_with_git() {
    git status -s 2>/dev/null | fzf --preview 'git diff {}'
}

search_processes() {
    ps aux | fzf --preview 'echo {}'
}

# Main Menu
while true; do
    show_help
    read -rp "Choose an option: " choice
    case $choice in
        1) search_current_directory ;;
        2) search_entire_system ;;
        3) search_text_in_files ;;
        4) search_recent_files ;;
        5) search_hidden_files ;;
        6) search_by_file_type ;;
        7) find_large_files ;;
        8) interact_with_git ;;
        9) search_processes ;;
        0) echo -e "${COLOR_GREEN}Exiting...${COLOR_RESET}" && exit 0 ;;
        *) handle_error "Invalid choice" ;;
    esac
done
