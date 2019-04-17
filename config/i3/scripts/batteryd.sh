#!/bin/bash

LOCKFILE=/tmp/.batteryd_lock
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then exit; fi
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

function message() {
	dunstify -t 10000 2690 -u critical "$1"
}

while true; do
	sleep 10

	if ! upower -i `upower -e | grep BAT` |\
		grep 'state.*discharging' &> /dev/null; then
		continue
	fi

	VALUE=$(upower -i `upower -e | grep BAT` |\
		grep percentage | grep -o "[0-9]*")

	if [ "$VALUE" -le 7 ]; then
		TEXT="Battery level critical! Hibernating in 5 seconds!"
		message "$TEXT"
		sleep 5
		~/.config/i3/scripts/hibernate.sh
	elif [ "$VALUE" -le 15 ]; then
		TEXT="Battery level low!"
		message "$TEXT"
	fi

done
