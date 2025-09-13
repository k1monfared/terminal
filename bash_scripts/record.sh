#!/bin/sh

#requires package sox from the repositories

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Backup path ##
FILE="$HOME/recording/rec-$DATETIME.wav"
rec $FILE
