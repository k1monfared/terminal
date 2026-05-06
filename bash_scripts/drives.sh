#!/bin/bash
# drives.sh - External USB drive utilities
# Source this from bashrc_aliases

# Check if a block device is USB-connected
_is_usb() {
    local dev="${1##*/}"
    local disk=$(echo "$dev" | sed 's/[0-9]*$//')
    [[ -d "/sys/block/$disk" ]] && readlink -f "/sys/block/$disk" | grep -q "usb"
}

# Get model name from parent disk device
_disk_model() {
    local dev="${1##*/}"
    local disk=$(echo "$dev" | sed 's/[0-9]*$//')
    lsblk -ndo MODEL "/dev/$disk" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Fix and mount dirty NTFS USB drives
# Usage: fix_mount [device] [label]
#   No args: auto-detects unmounted NTFS USB partitions
#   device:  specific partition like /dev/sda1
#   label:   mount directory name under /media/$USER/ (default: external)
fix_mount() {
    local device="$1"
    local label="${2:-external}"

    if [[ -z "$device" ]]; then
        local found=()
        local NAME TYPE FSTYPE MOUNTPOINT
        while IFS= read -r line; do
            eval "$line"
            [[ "$TYPE" != "part" ]] && continue
            [[ -n "$MOUNTPOINT" ]] && continue
            [[ "$FSTYPE" != "ntfs" ]] && continue
            _is_usb "$NAME" && found+=("$NAME")
        done < <(lsblk -Ppo NAME,TYPE,FSTYPE,MOUNTPOINT)

        if [[ ${#found[@]} -eq 0 ]]; then
            echo "No unmounted NTFS USB drives found."
            echo "Usage: fix_mount [device] [label]"
            return 1
        elif [[ ${#found[@]} -eq 1 ]]; then
            device="${found[0]}"
            echo "Found: $device ($(_disk_model "$device"))"
        else
            echo "Multiple NTFS USB partitions found:"
            for d in "${found[@]}"; do echo "  $d ($(_disk_model "$d"))"; done
            echo "Specify one: fix_mount /dev/sdX1 [label]"
            return 1
        fi
    fi

    if [[ ! -b "$device" ]]; then
        echo "Device $device not found"
        return 1
    fi

    local mount_point="/media/$USER/$label"

    echo "Fixing $device..."
    sudo ntfsfix "$device" || { echo "ntfsfix failed"; return 1; }

    sudo mkdir -p "$mount_point"
    echo "Mounting to $mount_point..."
    sudo mount -t ntfs-3g "$device" "$mount_point" 2>/dev/null || \
    sudo mount -t ntfs3 -o force "$device" "$mount_point" || {
        echo "Mount failed"
        return 1
    }

    echo "Done. Drive at $mount_point"
}

# Interactive checkbox selector
# Draws UI to /dev/tty, outputs selected indices to stdout
_checkbox_select() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    local total=$((count + 2))
    local selected=()
    local cursor=2
    local lines_drawn=0

    for ((i = 0; i < count; i++)); do selected[$i]=0; done

    tput civis >/dev/tty
    trap 'tput cnorm >/dev/tty 2>/dev/null' RETURN
    trap 'tput cnorm >/dev/tty 2>/dev/null; return 1' INT

    _draw() {
        [[ $lines_drawn -gt 0 ]] && printf '\033[%dA' "$lines_drawn" >/dev/tty

        local n=0

        printf "\033[2K  \033[1;36m?\033[0m \033[1m%s\033[0m\n" "$title" >/dev/tty; ((n++))
        printf "\033[2K\n" >/dev/tty; ((n++))

        # All
        if [[ $cursor -eq 0 ]]; then
            printf "\033[2K  \033[36m›\033[0m \033[36m○\033[0m \033[1mAll\033[0m\n" >/dev/tty
        else
            printf "\033[2K    \033[2m○ All\033[0m\n" >/dev/tty
        fi; ((n++))

        # None
        if [[ $cursor -eq 1 ]]; then
            printf "\033[2K  \033[36m›\033[0m \033[36m○\033[0m \033[1mNone\033[0m\n" >/dev/tty
        else
            printf "\033[2K    \033[2m○ None\033[0m\n" >/dev/tty
        fi; ((n++))

        # Separator
        printf "\033[2K    \033[2m─────────────────────────────────────────────\033[0m\n" >/dev/tty; ((n++))

        # Drive items
        for ((i = 0; i < count; i++)); do
            local idx=$((i + 2)) mark color
            if [[ ${selected[$i]} -eq 1 ]]; then
                mark="●" color="\033[32m"
            else
                mark="○" color="\033[2m"
            fi

            if [[ $cursor -eq $idx ]]; then
                printf "\033[2K  \033[36m›\033[0m ${color}${mark}\033[0m \033[1m%s\033[0m\n" "${items[$i]}" >/dev/tty
            else
                printf "\033[2K    ${color}${mark}\033[0m %s\n" "${items[$i]}" >/dev/tty
            fi; ((n++))
        done

        printf "\033[2K\n" >/dev/tty; ((n++))
        printf "\033[2K  \033[2m↑↓ move  space select  enter confirm  q cancel\033[0m\n" >/dev/tty; ((n++))

        lines_drawn=$n
    }

    _draw

    while IFS= read -rsn1 key </dev/tty; do
        case "$key" in
            q|Q) return 1 ;;
            '')
                for ((i = 0; i < count; i++)); do
                    [[ ${selected[$i]} -eq 1 ]] && echo "$i"
                done
                return 0
                ;;
            ' ')
                if [[ $cursor -eq 0 ]]; then
                    for ((i = 0; i < count; i++)); do selected[$i]=1; done
                elif [[ $cursor -eq 1 ]]; then
                    for ((i = 0; i < count; i++)); do selected[$i]=0; done
                else
                    local idx=$((cursor - 2))
                    selected[$idx]=$(( 1 - ${selected[$idx]} ))
                fi
                _draw ;;
            $'\x1b')
                read -rsn2 seq </dev/tty
                case "$seq" in
                    '[A') cursor=$(( (cursor - 1 + total) % total )); _draw ;;
                    '[B') cursor=$(( (cursor + 1) % total )); _draw ;;
                esac ;;
        esac
    done
}

# Safely eject USB drives
# Single drive: confirms and ejects
# Multiple drives: interactive checkbox selection
eject() {
    local drive_data=()
    local drive_labels=()
    local NAME TYPE MOUNTPOINT SIZE

    while IFS= read -r line; do
        eval "$line"
        [[ "$TYPE" != "part" ]] && continue
        [[ -z "$MOUNTPOINT" ]] && continue
        [[ "$MOUNTPOINT" == /snap/* || "$MOUNTPOINT" == /boot/* ]] && continue
        [[ "$MOUNTPOINT" == "/" || "$MOUNTPOINT" == "[SWAP]" || "$MOUNTPOINT" == /run/* ]] && continue
        _is_usb "$NAME" || continue

        local model=$(_disk_model "$NAME")
        drive_data+=("$NAME|$MOUNTPOINT|$SIZE|$model")
        drive_labels+=("$(printf "%-8s  %-24s  %5s  →  %s" "${NAME##*/}" "$model" "$SIZE" "$MOUNTPOINT")")
    done < <(lsblk -Ppo NAME,TYPE,MOUNTPOINT,SIZE)

    local count=${#drive_data[@]}

    if [[ $count -eq 0 ]]; then
        echo "No mounted USB drives found."
        return 0
    fi

    local selected_indices=()

    if [[ $count -eq 1 ]]; then
        local dev mnt size model
        IFS='|' read -r dev mnt size model <<< "${drive_data[0]}"
        printf "  \033[1;36m?\033[0m Safely remove \033[1m%s\033[0m (%s)? [Y/n] " "${model:-$dev}" "$dev"
        read -r confirm </dev/tty
        [[ "$confirm" =~ ^[Nn] ]] && { echo "  Cancelled."; return 0; }
        selected_indices=(0)
    else
        local result rc
        result=$(_checkbox_select "Select drives to safely remove:" "${drive_labels[@]}")
        rc=$?
        [[ $rc -ne 0 || -z "$result" ]] && { echo "  No drives selected."; return 0; }
        mapfile -t selected_indices <<< "$result"
    fi

    echo ""
    for idx in "${selected_indices[@]}"; do
        [[ -z "$idx" ]] && continue
        local dev mnt size model
        IFS='|' read -r dev mnt size model <<< "${drive_data[$idx]}"
        local parent="/dev/$(echo "${dev##*/}" | sed 's/[0-9]*$//')"

        printf "  Syncing..."
        sync
        printf " done\n"

        printf "  Unmounting %s..." "$mnt"
        if sudo umount "$mnt" 2>/dev/null; then
            printf " done\n"
        else
            printf " \033[31mfailed\033[0m\n"
            continue
        fi

        printf "  Powering off %s..." "$parent"
        if command -v udisksctl &>/dev/null && udisksctl power-off -b "$parent" 2>/dev/null; then
            printf " done\n"
        else
            printf " \033[2m(safe to unplug)\033[0m\n"
        fi

        printf "  \033[32m✓\033[0m %s safely removed\n\n" "${model:-$dev}"
    done
}
