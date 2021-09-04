#!/bin/sh

## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")
 
## Backup path ##
BAK="/home/$USER/drafts"
FILE=$BAK/note-$DATE-$TIME

input=$*
echo "$input" >> "$FILE"
echo $FILE >> $BAK/list #this adds the name of the file to the list of the files. I'm going to read that list later to access the last file, or one before last file, and so on!
echo $FILE #this will echo the file name and address in the terminal so that I know the name of it if I need it and that I know everything worked fine.
