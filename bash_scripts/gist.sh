#!/bin/sh
 
## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")
  
## Save path ##
BAK="/home/$USER/drafts"

## the name of the gist file ##
input=$*

## filename ##
FILE="$BAK/gist-$DATE-$TIME-$input"

gedit $FILE 2>/dev/null
gh gist create -w -f $FILE $FILE
