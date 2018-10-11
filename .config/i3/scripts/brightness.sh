#!/bin/bash

function show_notification {
	icon=$1
	brightness=$2

	# Format the volume
	brightness_text=$(printf %3d%% $brightness)

	# Limit the volume
	if [ $brightness -lt 0 ]; then brightness=0; fi
	if [ $brightness -gt 100 ]; then brightness=100; fi

	if [ -z $icon ] || [ -z $brightness ]; then exit; fi

	bar=$(seq -s '─' $((brightness / 4)) | sed 's/[0-9]//g')

	dunstify -t 1000 -i "$icon" -r 2593 -u normal "$brightness_text $bar"
}

LOCKFILE=/tmp/.brightness_lock
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then exit; fi
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

if [ "$1" == "up" ]; then
	sudo xbacklight -inc 5
elif [ "$1" == "down" ]; then
	sudo xbacklight -dec 5
fi

VALUE=$(xbacklight -get | egrep -o "^[0-9]*")

ICON="display-brightness"

#notify-send ' ' -i $ICON -h int:value:$VALUE -h string:synchronous:brightness
show_notification $ICON $VALUE

rm -f ${LOCKFILE}
