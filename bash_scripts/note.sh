#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Save path ##
mkdir -p -- "$drafts_folder"
filename="note_$DATETIME"

SUBFOLDER="$*"
SAVE_DIR="$drafts_folder"
FIRST_LINE=""

if [ -n "$SUBFOLDER" ]; then
    if [ -d "$drafts_folder/$SUBFOLDER" ]; then
        SAVE_DIR="$drafts_folder/$SUBFOLDER"
    else
        create_option="Create '$SUBFOLDER' (as typed)"
        options="$create_option"
        for d in "$drafts_folder"/*/; do
            [ -d "$d" ] || continue
            options="$options
$(basename "$d")"
        done

        selection=$(printf '%s\n' "$options" | picker \
            --header "Folder '$SUBFOLDER' not found. Pick or type a name:" \
            --custom)

        case "$selection" in
            "$create_option")
                mkdir -p -- "$drafts_folder/$SUBFOLDER"
                SAVE_DIR="$drafts_folder/$SUBFOLDER"
                ;;
            "")
                FIRST_LINE="$SUBFOLDER"
                ;;
            *)
                mkdir -p -- "$drafts_folder/$selection"
                SAVE_DIR="$drafts_folder/$selection"
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
