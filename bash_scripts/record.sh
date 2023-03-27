#!/bin/sh

#requires package sox from the repositories

## date format ##
DATETIME=$(date +"%Y%m%d_%H%M%S")
## Backup path ##
FILE="/home/$USER/drafts/recorded-$DATETIME.wav"
rec $FILE
