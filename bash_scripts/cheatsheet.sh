#!/bin/bash
# Interactive two-level command cheatsheet
# Level 1: pick a group   Level 2: pick a command inside that group
# Usage: cheatsheet / cheat / cs            (print table)
#        cheatsheet -i / cheat -i / cs -i   (interactive menu)

# Colors
C_RESET='\033[0m'
C_DIM='\033[2m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BOLD_WHITE='\033[1;37m'
C_BOLD='\033[1m'
C_BOLD_GREEN='\033[1;32m'
C_WHITE='\033[37m'

# Each entry: "GROUP|COMMAND|DESCRIPTION|ACTUAL_COMMAND"
ENTRIES=(
    "System|hib|Hibernate|sudo systemctl hibernate"
    "System|bat|Better cat|batcat"
    "System|ip|Public IP info|curl -s ipinfo.io"
    "System|vnc|VNC server|~/opt/vnc-manager.sh"
    "System|plotbills|Plot bills|bash \$HOME/Documents/money/bills/plot_bills.sh"
    "System|rotate|Rotate display|sh \$bashscripts/rotate.sh"
    "System|brightness|Screen brightness|sh \$bashscripts/brightness.sh"

    "Packages|ins|Install package|sudo apt install"
    "Packages|upd|Update pkg list|sudo apt update"
    "Packages|upg|Upgrade all|sudo apt upgrade -y"
    "Packages|remove|Remove package|sudo apt remove"
    "Packages|upg-secure|Security upgrade|sudo unattended-upgrade"

    "Notes|note|New timestamped note|sh \$bashscripts/note.sh"
    "Notes|n|Quick note append|sh \$bashscripts/quicknote.sh"
    "Notes|ln|Open last note|sh \$bashscripts/lastnote.sh"
    "Notes|notes|Search notes (fzf)|search_notes"
    "Notes|blog|New blog post|sh \$bashscripts/blog.sh"
    "Notes|pn|Open public note|pn"
    "Notes|pvn|Open private note|pvn"
    "Notes|movie|Movie notes|\$HOME/public/notes/movie"

    "Memory|mem|Save to memory|sh \$bashscripts/memory.sh"
    "Memory|remem|Search memory|remem"
    "Memory|cap|Capture output|cap"
    "Memory|ret|Retrieve captured|ret"

    "Search|search|DuckDuckGo|sh \$bashscripts/duckduckgo.sh"
    "Search|contacts|Google Contacts|sh \$bashscripts/contacts.sh"
    "Search|fz|Fuzzy find here|fz"
    "Search|fza|Fuzzy find all|fza"

    "Git|git_switch|Switch git account|sh \$bashscripts/git_switch.sh"
    "Git|git_who|Active git account|git_who"
    "Git|git_init|Init + GitHub repo|git_init"
    "Git|git_push_all|Stage commit push|git_push_all"
    "Git|git_clone|Clone with account|git_clone"
    "Git|gh_switch|Switch GitHub user|gh_switch"
    "Git|gist|Gist from file|sh \$bashscripts/gist.sh"
    "Git|gistp|Private gist|sh \$bashscripts/publicgist.sh"
    "Git|gg|Quick gist (clip)|sh \$bashscripts/quickgist.sh"

    "Files|cb|File to clipboard|sh \$bashscripts/copy_file_to_clipboard.sh"
    "Files|organize|Photos by month|sh \$bashscripts/organize_photos_monthly_this_folder.sh"
    "Files|enc|Encrypt (AES256)|enc"
    "Files|dec|Decrypt file|dec"

    "Passwords|bw|Bitwarden CLI|\$HOME/opt/bw"
    "Passwords|bwc|Bitwarden copy|\$bashscripts/bwc"
    "Passwords|bwu|Unlock Bitwarden|bwu"
    "Passwords|bwl|Lock Bitwarden|bwl"

    "Backup|backup|Backup manager|bash \$HOME/opt/BackupSystem/scripts/backup_manager.sh"
    "Backup|backup-recovery|Backup rollback|bash \$HOME/opt/BackupSystem/scripts/backup_recovery.sh"
    "Backup|backup_phone|Backup phone|backup_phone"
    "Backup|backup_laptop|Backup laptop|backup_laptop"

    "Photos|photoblog|Photoblog editor|python ~/public/photoblog/scripts/editor.py"
    "Photos|copy_canon|Copy from Canon|sh \$bashscripts/copy_canon.sh"

    "Media|mic|Record audio|sh \$bashscripts/record.sh"
    "Media|yt|YouTube (repeat)|yt"
    "Media|ytn|YouTube (N times)|ytn"
    "Media|ytp|YouTube (once)|ytp"
    "Media|libby_get|Organize audiobooks|libby_get"

    "Projects|new_project|Create project|new_project"
    "Projects|project-status|All statuses|project-status"
    "Projects|list-projects|List with stages|list-projects"
    "Projects|update-status|Regen master status|update-status"
    "Projects|psproject|View one project|psproject"
    "Projects|edit-status|Edit project status|edit-status"
    "Projects|cdpublic|Go to ~/public|cd \$HOME/public"
    "Projects|demo|Review app demo|demo"
    "Projects|casetracker|Case tracker|casetracker"
    "Projects|caseatlas|Case atlas|caseatlas"

    "API|use-poe|Switch to Poe|use-poe"
    "API|use-claude-api|Switch to Claude API|use-claude-api"
    "API|use-claude|Default Claude Code|use-claude"
    "API|check-claude-config|Show API config|check-claude-config"

    "VPN|ppn|ProtonVPN CLI|protonvpn-cli"

    "News|iran_news|News pipeline|iran_news"

    "Todo|t|Todo.txt CLI|t"

    "Drives|fix_mount|Fix dirty USB|fix_mount"
    "Drives|eject|Eject USB drive|eject"

    "Tools|jnb|Jupyter Notebook|jupyter notebook"
    "Tools|aliases_edit|Edit aliases file|aliases_edit"
    "Tools|aliases_list|List all aliases|aliases_list"
)

# Group display order and colors
declare -A _GRP_COLORS
_GRP_COLORS=(
    ["System"]="\033[1;36m"
    ["Packages"]="\033[1;33m"
    ["Notes"]="\033[1;32m"
    ["Memory"]="\033[1;35m"
    ["Search"]="\033[1;34m"
    ["Git"]="\033[1;31m"
    ["Files"]="\033[1;36m"
    ["Passwords"]="\033[1;33m"
    ["Backup"]="\033[1;31m"
    ["Photos"]="\033[1;35m"
    ["Media"]="\033[1;34m"
    ["Projects"]="\033[1;32m"
    ["API"]="\033[1;36m"
    ["VPN"]="\033[1;33m"
    ["News"]="\033[1;34m"
    ["Todo"]="\033[1;35m"
    ["Drives"]="\033[1;31m"
    ["Tools"]="\033[1;32m"
)

_GRP_ORDER=("System" "Packages" "Notes" "Memory" "Search" "Git" "Files" "Passwords" "Backup" "Photos" "Media" "Projects" "API" "VPN" "News" "Todo" "Drives" "Tools")

# ── Print the full reference table ──────────────────────────────────────────
show_table() {
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 100)

    local cmd_w=17
    local desc_w=20
    local col_w=$(( cmd_w + desc_w + 3 ))
    local cols=$(( term_width / col_w ))
    [[ $cols -lt 1 ]] && cols=1
    [[ $cols -gt 3 ]] && cols=3

    echo ""
    printf "  ${C_BOLD_WHITE}COMMAND CHEATSHEET${C_RESET}  ${C_DIM}use -i for interactive menu${C_RESET}\n"
    local line_w=$(( term_width - 4 ))
    printf "  ${C_DIM}"
    printf '%.0s─' $(seq 1 $line_w)
    printf "${C_RESET}\n\n"

    for group in "${_GRP_ORDER[@]}"; do
        local color="${_GRP_COLORS[$group]}"
        local items=()

        for entry in "${ENTRIES[@]}"; do
            local g="${entry%%|*}"
            [[ "$g" == "$group" ]] && items+=("$entry")
        done
        [[ ${#items[@]} -eq 0 ]] && continue

        printf "  %b▸ %-12s%b" "$color" "$group" "$C_RESET"

        local i=0
        local first_row=true
        while [[ $i -lt ${#items[@]} ]]; do
            if [[ "$first_row" != true ]]; then
                printf "  %b  %-12s%b" "$C_DIM" "" "$C_RESET"
            fi
            first_row=false
            for (( c=0; c<cols && i<${#items[@]}; c++, i++ )); do
                local entry="${items[$i]}"
                IFS='|' read -r _ cmd desc _ <<< "$entry"
                printf "%b%-${cmd_w}s%b%-${desc_w}s%b " "$C_BOLD_GREEN" "$cmd" "$C_WHITE" "$desc" "$C_RESET"
            done
            printf "\n"
        done
        # separator line between sections
        printf "  ${C_DIM}"
        printf '%.0s─' $(seq 1 $line_w)
        printf "${C_RESET}\n"
    done
    echo ""
}

# ── Count commands in a group ───────────────────────────────────────────────
count_group() {
    local target="$1"
    local n=0
    for entry in "${ENTRIES[@]}"; do
        [[ "${entry%%|*}" == "$target" ]] && (( n++ ))
    done
    echo "$n"
}

# ── Level 1: pick a group ──────────────────────────────────────────────────
pick_group() {
    local lines=()
    for group in "${_GRP_ORDER[@]}"; do
        local color="${_GRP_COLORS[$group]}"
        local n
        n=$(count_group "$group")
        lines+=("$(printf "%b▸ %-12s%b  %b%d commands%b" "$color" "$group" "$C_RESET" "$C_DIM" "$n" "$C_RESET")")
    done

    printf '%s\n' "${lines[@]}" | fzf \
        --ansi \
        --no-sort \
        --exact \
        --pointer "▸" \
        --prompt "  Group> " \
        --color "fg:7,bg:-1,hl:6,fg+:15,bg+:236,hl+:14,info:3,prompt:2,pointer:1,marker:5,spinner:3" \
        --layout=reverse \
        --height=$(( ${#_GRP_ORDER[@]} + 4 )) \
        --no-scrollbar \
        --border=rounded \
        --border-label=" choose a group " \
        --bind "change:first"
}

# ── Level 2: pick a command inside the chosen group ─────────────────────────
pick_command() {
    local target_group="$1"
    local color="${_GRP_COLORS[$target_group]}"
    local lines=()

    for entry in "${ENTRIES[@]}"; do
        IFS='|' read -r g cmd desc actual <<< "$entry"
        if [[ "$g" == "$target_group" ]]; then
            lines+=("$(printf "%b%-17s%b %b%s%b" "$C_BOLD_GREEN" "$cmd" "$C_RESET" "$C_WHITE" "$desc" "$C_RESET")")
        fi
    done

    local label
    label=$(printf " %s " "$target_group")

    printf '%s\n' "${lines[@]}" | fzf \
        --ansi \
        --no-sort \
        --exact \
        --pointer "▸" \
        --prompt "  Command> " \
        --color "fg:7,bg:-1,hl:6,fg+:15,bg+:236,hl+:14,info:3,prompt:2,pointer:1,marker:5,spinner:3" \
        --layout=reverse \
        --height=$(( ${#lines[@]} + 4 )) \
        --no-scrollbar \
        --border=rounded \
        --border-label="$label" \
        --bind "change:first"
}

# ── Look up the actual command string ───────────────────────────────────────
lookup_command() {
    local selected_cmd="$1"
    for entry in "${ENTRIES[@]}"; do
        IFS='|' read -r _ cmd desc actual <<< "$entry"
        [[ "$cmd" == "$selected_cmd" ]] && echo "$actual" && return
    done
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
    # Always print the full table so it stays in scrollback
    show_table

    if [[ "$1" != "-i" && "$1" != "--interactive" ]]; then
        return 0
    fi

    # Level 1: pick group
    local group_line
    group_line=$(pick_group)
    [[ -z "$group_line" ]] && return 0

    # Extract group name (strip ANSI, grab word after ▸)
    local group_name
    group_name=$(echo "$group_line" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/^.*▸ *//' | awk '{print $1}')

    # Level 2: pick command inside group
    local cmd_line
    cmd_line=$(pick_command "$group_name")
    [[ -z "$cmd_line" ]] && return 0

    # Extract command name
    local cmd_name
    cmd_name=$(echo "$cmd_line" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
    local actual_cmd
    actual_cmd=$(lookup_command "$cmd_name")

    echo ""
    printf "  %bRunning:%b %b%s%b %b(%s)%b\n" "$C_BOLD" "$C_RESET" "$C_YELLOW" "$cmd_name" "$C_RESET" "$C_DIM" "$actual_cmd" "$C_RESET"
    echo ""

    eval "$actual_cmd"
}

main "$@"
