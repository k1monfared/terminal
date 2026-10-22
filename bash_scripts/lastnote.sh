#!/bin/bash
. "$(cd "$(dirname "$0")" && pwd)/lib/platform.sh"

#if [[ $(echo $*) ]]; then
#    N=$*
#else
#    N=1
#fi
N=1
FILE=$(tail -$N "$drafts_folder/list" | head -1)

$EDITOR "$FILE" 2>/dev/null &
