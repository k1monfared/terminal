#!/bin/bash

status=$(xrandr --verbose | grep LVDS-1 | awk '{print $6}')
if test inverted = $status
then
xrandr -o normal && xsetwacom list | grep stylus | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate none && xsetwacom list | grep eraser | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate none && xinput list | grep TouchPad | awk '{print $6}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 1 && xinput list | grep TrackPoint | awk '{print $6}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 1 && xinput list | grep Finger | awk '{print $8}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 1
fi

if test normal = $status
then
xrandr -o inverted && xsetwacom list | grep stylus | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate half && xsetwacom list | grep eraser | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate half && xinput list | grep TouchPad | awk '{print $6}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 0 && xinput list | grep TrackPoint | awk '{print $6}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 0 && xinput list | grep Finger | awk '{print $8}' | sed 's/^id=//' | xargs -Idevice xinput set-prop device "Device Enabled" 0
fi

##xrandr --output LVDS1 --rotate inverted
##xsetwacom list | grep stylus | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate half
##there is no touch in xsetwacom anymore:
##xsetwacom list | grep touch | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate half && 
##xsetwacom list | grep touch | awk '{print $7}' | xargs -Idevice xsetwacom set device Rotate none && 
