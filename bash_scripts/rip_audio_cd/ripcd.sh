#!/bin/bash
# A simple shell script to rip audio cd and create mp3 using lame 
# and cdparanoia utilities.
# ----------------------------------------------------------------------------
# Written by Vivek Gite <http://www.cyberciti.biz/>
# (c) 2006 nixCraft under GNU GPL v2.0+
# ----------------------------------------------------------------------------
read -p "Starting in 5 seconds ( to abort press CTRL + C ) " -t 5
cdparanoia -B
for i in *.wav
do
 lame --vbr-new -b 360 "$i" "${i%%.cdda.wav}.mp3"
 rm -f "$i"
done
