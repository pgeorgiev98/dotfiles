#!/bin/bash

pipe=/tmp/.controlpipe

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	echo "Usage:"
	echo "  $0 [brightness_up] [brightness_down]"
	echo "  $0 [volume_up] [volume_down] [volume_toggle_mute]"
	exit
fi

if [[ $# -ge 1 ]]; then
	if [[ -p $pipe ]]; then
		echo $@ > $pipe
		exit
	else
		echo "Daemon is not running"
		exit 1
	fi
fi

trap "rm -f $pipe" EXIT

if [[ ! -p $pipe ]]; then
	mkfifo $pipe
fi

function show_notification {
	type=$1
	percent=$2

	text="$percent%"

	icons_path='/usr/share/icons/Adwaita/24x24/status'
	if [[ "$type" == "brightness" ]]; then
		icon="$icons_path/display-brightness-symbolic.symbolic.png"
	elif [[ "$type" == "volume" ]]; then
		if [[ "$3" == "muted" ]]; then
			icon="$icons_path/audio-volume-muted-symbolic.symbolic.png"
		elif [[ $percent -le 33 ]]; then
			icon="$icons_path/audio-volume-low-symbolic.symbolic.png"
		elif [[ $percent -le 66 ]]; then
			icon="$icons_path/audio-volume-medium-symbolic.symbolic.png"
		elif [[ $percent -le 100 ]]; then
			icon="$icons_path/audio-volume-high-symbolic.symbolic.png"
		else
			icon="$icons_path/audio-volume-overamplified-symbolic.symbolic.png"
		fi
	fi

	# Limit the percentage
	if [ $percent -lt 0 ]; then percent=0; fi
	if [ $percent -gt 100 ]; then percent=100; fi

	bar=$(seq -s '─' $((percent / 4)) | sed 's/[0-9]//g')

	dunstify -t 1000 -i "$icon" -r 2593 -u normal "$text $bar"
}

icons_path='/usr/share/icons/HighContrast/32x32'
brightness_icon="$icons_path/display-brightness"

function brightness_up {
	~/.config/i3/scripts/backlight.sh -inc 5
	show_notification brightness $(~/.config/i3/scripts/backlight.sh -get)
}

function brightness_down {
	~/.config/i3/scripts/backlight.sh -dec 5
	show_notification brightness $(~/.config/i3/scripts/backlight.sh -get)
}

function volume_up {
	sink=$(pactl list | grep '^Sink #[0-9]*$' | head -n1 | grep '[0-9]*' -o)
	volume=$(pactl list sinks | grep '^[[:space:]]Volume:' | \
		head -n $(( $sink + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
	muted=$(pactl list sinks | grep 'Mute: .*$' | head -n 1 | awk '{print $2}')

	pactl set-sink-volume $sink +5%&
	if [[ "$muted" == "yes" ]]; then
		show_notification volume $((volume+5)) muted&
	else
		show_notification volume $((volume+5))&
	fi
}

function volume_down {
	sink=$(pactl list | grep '^Sink #[0-9]*$' | head -n1 | grep '[0-9]*' -o)
	volume=$(pactl list sinks | grep '^[[:space:]]Volume:' | \
		head -n $(( $sink + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
	muted=$(pactl list sinks | grep 'Mute: .*$' | head -n 1 | awk '{print $2}')

	pactl set-sink-volume $sink -5%&
	if [[ "$muted" == "yes" ]]; then
		show_notification volume $((volume-5)) muted&
	else
		show_notification volume $((volume-5))&
	fi
}

function volume_toggle_mute {
	sink=$(pactl list | grep '^Sink #[0-9]*$' | head -n1 | grep '[0-9]*' -o)
	volume=$(pactl list sinks | grep '^[[:space:]]Volume:' | \
		head -n $(( $sink + 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
	muted=$(pactl list sinks | grep 'Mute: .*$' | head -n 1 | awk '{print $2}')

	pactl set-sink-mute $sink toggle
	if [[ "$muted" == "yes" ]]; then
		show_notification volume $((volume))&
	else
		show_notification volume $((volume)) muted&
	fi
}

while true; do
	if read word <$pipe; then
		if [[ "$word" == "volume_up" ]]; then
			volume_up
		elif [[ "$word" == "volume_down" ]]; then
			volume_down
		elif [[ "$word" == "volume_toggle_mute" ]]; then
			volume_toggle_mute
		elif [[ "$word" == "brightness_up" ]]; then
			brightness_up
		elif [[ "$word" == "brightness_down" ]]; then
			brightness_down
		fi
	fi
done
