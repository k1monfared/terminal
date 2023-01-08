#!/bin/sh

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")

## Save path ##
BAK="/home/$USER/drafts"
filename="note_$DATETIME"
FILE="$BAK/$filename"
# open the editor to add text
atom $FILE 2>/dev/null & # The 2>/dev/null part ignores the error messages in the command prompt output. It is assuming /dev/null exists though!
echo "file is saved at the following address:"
echo $FILE #this will echo the file name and address in the terminal so that I know the name of it if I need it and that I know everything worked fine.
echo $FILE >> $BAK/list

# if you want to add functionality to rename the file afterwards
# read -p "do you want to change the name of the file? (y/[n]) " response
#
# case $response in
#     [Yy]* )
#         read -p "Enter new file name: " filename
#         NEWFILE="$BAK/$filename"
#         mv $FILE $NEWFILE
#         echo $NEWFILE
#         echo $NEWFILE >> $BAK/list #this adds the name of the file to the list of the files. I'm going to read that list later to access the last file, or one before last file, and so on!
#     ;;
#     * )
#         echo $FILE >> $BAK/list
# esac
