#!/bin/sh
. "$(cd "$(dirname "$0")" && pwd)/lib/platform.sh"
 
## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")
  
## Save path ##
BAK="$drafts_folder"
mkdir -p -- "$BAK"

## filename ##
FILE="$BAK/quickgist-$DATE-$TIME"

## the name of the gist file ##
input=$*

echo "$input" >> "$FILE"

gh gist create -w -f $FILE $FILE
