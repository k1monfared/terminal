#!/bin/sh

## date format ##
YEAR=$(date +"%Y")
DATETIME=$(date +"%Y%m%d_")
blog_folder="${blog_folder%/}"
## Save path ##
mkdir -p -- "$blog_folder/posts/$YEAR"
filename="$DATETIME"
FILE="$blog_folder/posts/$YEAR/$filename"
echo $EDITOR
$EDITOR $FILE 2>/dev/null &
echo "file is saved at the following address:"
echo $FILE
echo $FILE >> $blog_folder/list
