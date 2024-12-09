#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Save path ##
BAK="$HOME/Documents/drafts"
mkdir -p -- "$BAK"
filename="note_$DATETIME"
FILE="$BAK/$filename"
pulsar $FILE 2>/dev/null &
echo "file is saved at the following address:"
echo $FILE
echo $FILE >> $BAK/list