#!/bin/bash

STRING=$*
BACK="/home/$USER/drafts"
#echo $STRING
grep -irn --color=always "$STRING" $BACK | grep -v "~"
