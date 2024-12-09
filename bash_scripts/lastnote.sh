#!/bin/bash

#if [[ $(echo $*) ]]; then
#    N=$*
#else
#    N=1
#fi
N=1
FILE=$(tail -$N "/home/$USER/drafts/list" | head -1)

atom $FILE 2>/dev/null &
