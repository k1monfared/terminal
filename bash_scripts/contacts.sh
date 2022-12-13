#!/bin/bash

searchterm="$*"
searchterm=$(echo $searchterm | sed -e 's/\ /+/g')
firefox https://contacts.google.com/search/$searchterm
