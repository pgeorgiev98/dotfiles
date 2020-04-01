#!/bin/bash

BACKLIGHT_PATH='/sys/class/backlight/intel_backlight'

function print_help {
	echo "Usage:"
	echo "Get the current brightness level: $0 -get"
	echo "Set the brightness level: $0 -set 0-100"
	echo "Increase the brightness level: $0 -inc 0-100"
	echo "Decrease the brightness level: $0 -dec 0-100"
}

function set_brightness() {
	new_brightness=$1
	if [ $new_brightness -gt 100 ]; then
		new_brightness=100
	elif [ $new_brightness -lt 0 ]; then
		new_brightness=0
	fi
	new_brightness=$(((new_brightness*max_brightness)/100))
	echo $new_brightness > "$BACKLIGHT_PATH/brightness"
}

if [ $# -eq 0 ]; then
	print_help
	exit 0
fi

max_brightness=$(cat $BACKLIGHT_PATH/max_brightness)
brightness=$(cat $BACKLIGHT_PATH/brightness)
normalized_brightness=$(((brightness*100)/max_brightness))
reg='^[0-9]+$'

if [ "$1" == "-get" ]; then
	echo $normalized_brightness
elif [ "$1" == "-set" ] && [[ "$2" =~ $reg ]]; then
	set_brightness $2
elif [ "$1" == "-inc" ] && [[ "$2" =~ $reg ]]; then
	inc=$2
	set_brightness $((normalized_brightness+inc))
elif [ "$1" == "-dec" ] && [[ "$2" =~ $reg ]]; then
	dec=$2
	set_brightness $((normalized_brightness-dec))
else
	print_help
	exit 1
fi
