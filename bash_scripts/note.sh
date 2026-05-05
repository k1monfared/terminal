#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Save path ##
mkdir -p -- "$drafts_folder"
filename="note_$DATETIME"

SUBFOLDER="$1"
SAVE_DIR="$drafts_folder"
FIRST_LINE=""

if [ -n "$SUBFOLDER" ]; then
    if [ -d "$drafts_folder/$SUBFOLDER" ]; then
        SAVE_DIR="$drafts_folder/$SUBFOLDER"
    else
        create_option="Create '$SUBFOLDER' (as typed)"
        new_name_option="Type a new name..."

        options="$create_option"
        for d in "$drafts_folder"/*/; do
            [ -d "$d" ] || continue
            options="$options
$(basename "$d")"
        done
        options="$options
$new_name_option"

        if command -v fzf >/dev/null 2>&1; then
            selection=$(printf '%s\n' "$options" | fzf \
                --prompt="Folder for note > " \
                --header="'$SUBFOLDER' not found. Use ↑/↓ to pick, Enter to confirm." \
                --height=40% \
                --reverse \
                --no-info \
                --no-mouse)
        else
            echo "fzf not installed; saving in default folder."
            selection=""
        fi

        case "$selection" in
            "$create_option")
                mkdir -p -- "$drafts_folder/$SUBFOLDER"
                SAVE_DIR="$drafts_folder/$SUBFOLDER"
                ;;
            "$new_name_option")
                printf "New folder name: "
                read -r new_name
                if [ -n "$new_name" ]; then
                    mkdir -p -- "$drafts_folder/$new_name"
                    SAVE_DIR="$drafts_folder/$new_name"
                else
                    FIRST_LINE="$SUBFOLDER"
                fi
                ;;
            "")
                FIRST_LINE="$SUBFOLDER"
                ;;
            *)
                if [ -d "$drafts_folder/$selection" ]; then
                    SAVE_DIR="$drafts_folder/$selection"
                else
                    FIRST_LINE="$SUBFOLDER"
                fi
                ;;
        esac
    fi
fi

FILE="$SAVE_DIR/$filename"

if [ -n "$FIRST_LINE" ]; then
    printf '%s\n' "$FIRST_LINE" > "$FILE"
fi

code "$FILE" 2>/dev/null &
echo "file is saved at the following address:"
echo "$FILE"
echo "$FILE" >> "$drafts_folder/list"
