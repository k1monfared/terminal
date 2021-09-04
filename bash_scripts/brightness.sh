#!/bin/bash

#sudo chmod -c -v a+x+w /sys/class/backlight/intel_backlight/brightness

max_brightness=4648
min_brightness=0
increment=500

get_brightness () {
	var=$( cat /sys/class/backlight/intel_backlight/brightness )
	echo $var
}

increase () {

	var=$( get_brightness )
	newvar=$(( $var + $increment ))
	if [ $newvar -le $max_brightness ]; then
		echo $newvar > /sys/class/backlight/intel_backlight/brightness
	else
		echo $max_brightness > /sys/class/backlight/intel_backlight/brightness
	fi
}

decrease () {

	var=$( get_brightness )
	newvar=$(( $var - $increment ))
	if [ $newvar -ge $min_brightness ]; then
		echo $newvar > /sys/class/backlight/intel_backlight/brightness
	else
		echo $min_brightness > /sys/class/backlight/intel_backlight/brightness
	fi
}

if [ $1 = 'increase' ] || [ $1 = 'decrease' ]; then
	$1
else
	echo "Option $1 not found. Use either with option 'increase' or 'decrese'"
fi
