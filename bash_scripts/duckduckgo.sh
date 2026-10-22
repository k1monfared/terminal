#!/bin/bash
. "$(cd "$(dirname "$0")" && pwd)/lib/platform.sh"

searchterm="$*"
searchterm=$(echo $searchterm | sed -e 's/ /+/g')
browser "https://duckduckgo.com/?q=$searchterm"
