#!/bin/sh
 
## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")
  
## Save path ##
BAK="/home/$USER/drafts"

## filename ##
FILE="$BAK/quickgist-$DATE-$TIME"

## the name of the gist file ##
input=$*

echo "$input" >> "$FILE"

gh gist create -w -f $FILE $FILE
