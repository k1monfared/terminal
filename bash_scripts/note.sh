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
        printf "Folder '%s' does not exist. Create it? [y/N]: " "$SUBFOLDER"
        read answer
        case "$answer" in
            y|Y|yes|YES)
                mkdir -p -- "$drafts_folder/$SUBFOLDER"
                SAVE_DIR="$drafts_folder/$SUBFOLDER"
                ;;
            *)
                FIRST_LINE="$SUBFOLDER"
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
