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
        echo "Folder '$SUBFOLDER' not found in $drafts_folder."
        echo "Choose an option:"
        echo "  1) Create '$SUBFOLDER' (as typed)"

        existing=""
        i=2
        for d in "$drafts_folder"/*/; do
            [ -d "$d" ] || continue
            name=$(basename "$d")
            existing="$existing$name
"
            echo "  $i) $name"
            i=$((i + 1))
        done

        new_name_idx=$i
        echo "  $i) Type a new name"

        printf "Selection [1]: "
        read -r choice
        choice=${choice:-1}

        if [ "$choice" = "1" ]; then
            mkdir -p -- "$drafts_folder/$SUBFOLDER"
            SAVE_DIR="$drafts_folder/$SUBFOLDER"
        elif [ "$choice" = "$new_name_idx" ]; then
            printf "New folder name: "
            read -r new_name
            if [ -n "$new_name" ]; then
                mkdir -p -- "$drafts_folder/$new_name"
                SAVE_DIR="$drafts_folder/$new_name"
            else
                FIRST_LINE="$SUBFOLDER"
            fi
        else
            selected=$(printf '%s' "$existing" | sed -n "$((choice - 1))p")
            if [ -n "$selected" ] && [ -d "$drafts_folder/$selected" ]; then
                SAVE_DIR="$drafts_folder/$selected"
            else
                echo "Invalid selection. Saving in default folder."
                FIRST_LINE="$SUBFOLDER"
            fi
        fi
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
