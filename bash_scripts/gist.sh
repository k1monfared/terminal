#!/bin/sh
. "$(cd "$(dirname "$0")" && pwd)/lib/platform.sh"
 
## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")
  
## Save path ##
BAK="$drafts_folder"
mkdir -p -- "$BAK"

## the name of the gist file ##
input=$*

## filename ##
FILE="$BAK/gist-$DATE-$TIME-$input"

edit_wait "$FILE" 2>/dev/null
gh gist create -w -f $FILE $FILE
