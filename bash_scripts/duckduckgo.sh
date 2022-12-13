#!/bin/bash

searchterm="$*"
searchterm=$(echo $searchterm | sed -e 's/\ /+/g')
firefox https://duckduckgo.com/?q=$searchterm &
