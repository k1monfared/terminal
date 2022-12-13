#!/bin/sh

#requires package sox from the repositories

## date format ##
DATE=$(date +"%F")
TIME=$(date +"%T")

## Backup path ##
BAK=/home/$USER/drafts
FILE=$BAK/recorded-$DATE-$TIME

rec $FILE.wav
