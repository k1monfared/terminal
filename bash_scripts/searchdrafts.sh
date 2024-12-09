#!/bin/bash

STRING=$*
BACK="/home/$USER/Documents/drafts"
#echo $STRING
grep -irn --color=always "$STRING" $BACK | grep -v "~"
