#!/bin/bash

LOCKFILE=/tmp/.batteryd_lock
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then exit; fi
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

while true; do
	sleep 10

	DISCHARGING=$(upower -i `upower -e | grep BAT` |\
		grep state | grep discharging)

	if [ ! -n "$DISCHARGING" ]; then
		continue
	fi

	VALUE=$(upower -i `upower -e | grep BAT` |\
		grep percentage | grep -o "[0-9]*")

	function msg() {
		notify-send "$1" -i "$2" -t 1000
	}

	if [ "$VALUE" -le 7 ]; then
		TEXT="Battery level critical! Hibernating in 5 seconds!"
		msg "$TEXT" 'notification-battery-empty'
		sleep 5
		systemctl hibernate
	elif [ "$VALUE" -le 15 ]; then
		TEXT="Battery level low!"
		msg "$TEXT" 'notification-battery-low'
	fi

done

rm -f ${LOCKFILE}
