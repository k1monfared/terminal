#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_")
## Save path ##
mkdir -p -- "$blog_folder"
filename="note_$DATETIME"
FILE="$blog_folder/$filename"
code $FILE 2>/dev/null &
echo "file is saved at the following address:"
echo $FILE
echo $FILE >> $blog_folder/list
