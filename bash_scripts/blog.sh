#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_")
## Save path ##
mkdir -p -- "$blog_folder"
filename="$DATETIME"
FILE="$blog_folder$filename"
echo $EDITOR
$EDITOR $FILE 2>/dev/null &
echo "file is saved at the following address:"
echo $FILE
echo $FILE >> $blog_folder/list
