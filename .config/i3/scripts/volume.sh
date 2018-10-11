#!/bin/bash

function show_notification {
	icon=$1
	volume=$2

	# Format the volume
	volume_text=$(printf %3d%% $volume)

	# Limit the volume
	if [ $volume -lt 0 ]; then volume=0; fi
	if [ $volume -gt 100 ]; then volume=100; fi

	if [ -z $icon ] || [ -z $volume ]; then exit; fi

	bar=$(seq -s '─' $((volume / 4)) | sed 's/[0-9]//g')

	dunstify -t 1000 -i "$icon" -r 2593 -u normal "$volume_text $bar"
}

LOCKFILE=/tmp/.volume_lock
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then exit; fi
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

SINK=$(pactl list | grep '^Sink #[0-9]*$' | head -n1 | grep '[0-9]*' -o)

if [ "$1" == "down" ]; then
	pactl set-sink-volume $SINK -5%
elif [ "$1" == "up" ]; then
	pactl set-sink-volume $SINK +5%
elif [ "$1" == "mute" ]; then
	pactl set-sink-mute $SINK toggle
fi

VOLUME=$(pactl list sinks | grep '^[[:space:]]Volume:' | \
    head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
MUTED=$(pactl list sinks | grep 'Mute: .*$' | head -n 1 | awk '{print $2}')

if [ "$MUTED" == "yes" ]; then
	ICON="audio-volume-muted"
elif [ "$VOLUME" -le 34 ]; then
	ICON="audio-volume-low"
elif [ "$VOLUME" -le 67 ]; then
	ICON="audio-volume-medium"
else
	ICON="audio-volume-high"
fi

STATUS_PID=`pgrep ^status.sh$`
if [ ! -z "$STATUS_PID" ]; then
	for i in $STATUS_PID; do
		kill -SIGUSR1 $STATUS_PID
	done
fi

#notify-send " " -i $ICON -h int:value:$VOLUME -h string:synchronous:volume
show_notification $ICON $VOLUME

rm -f ${LOCKFILE}
