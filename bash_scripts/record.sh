#!/bin/sh

#requires sox (apt install sox / brew install sox)

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Backup path ##
FILE="$HOME/recording/rec-$DATETIME.wav"
mkdir -p "$(dirname "$FILE")"
rec "$FILE"
