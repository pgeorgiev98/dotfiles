#!/bin/bash

SLEEPPID=''

trap 'if [ ! -z $SLEEPPID ]; then kill -SIGINT $SLEEPPID; fi' SIGUSR1

function date_time {
	echo "  $(date +%Y-%m-%d)    $(date +%H:%M:%S)"
}

function battery {
	battery_level="$(cat /sys/class/power_supply/BAT0/capacity)"
	battery_icon=''
	if [ "$battery_level" -lt 15 ]; then
		battery_icon=''
	elif [ "$battery_level" -lt 40 ]; then
		battery_icon=''
	elif [ "$battery_level" -lt 65 ]; then
		battery_icon=''
	elif [ "$battery_level" -lt 90 ]; then
		battery_icon=''
	else
		battery_icon=''
	fi
	echo "$battery_icon  $battery_level%"
}

function volume {
	sink=$(pactl list short sinks | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,' | head -n 1 )
	level=$(pactl list sinks | grep '^[[:space:]]Volume:' | head -n $(( $sink+ 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,' )
	muted=$(pactl list sinks | grep '^[[:space:]]Mute:' | head -n $((sink+1)) | tail -n 1 | awk '{printf $2}')
	volume_icon=''
	if [ "$muted" == "yes" ]; then
		volume_icon=''
	elif [ "$level" -lt 50 ]; then
		volume_icon=''
	else
		volume_icon=''
	fi
	echo "$volume_icon  $level%"
}

function cpu {
	cpu_usage=[]
	touch /tmp/.cpu_stats_old
	grep '^cpu[0-9]' /proc/stat > /tmp/.cpu_stats_new
	i=0
	lines_count=`wc -l /tmp/.cpu_stats_new | awk '{print $1}'`
	for i in `seq 0 $((lines_count-1))`; do 
		read -r -a stats <<< `head -n $((i+1)) /tmp/.cpu_stats_new | tail -n 1`
		read -r -a old_stats <<< `head -n $((i+1)) /tmp/.cpu_stats_old | tail -n 1`
		s=(${stats[@]})
		for j in `seq 1 8`; do s[j]=$((s[j]-old_stats[j])); done
		total=$((s[1]+s[2]+s[3]+s[4]+s[5]+s[6]+s[7]+s[8]))
		idle=$((s[4]+s[5]))

		cpu_usage[i]=$(( 100 - (100*idle) / total ))
	done
	mv /tmp/.cpu_stats_new /tmp/.cpu_stats_old &> /dev/null

	usage_text='['
	for i in ${cpu_usage[@]}; do
		if [ $i -le 12 ]; then
			c='▁'
		elif [ $i -le 25 ]; then
			c='▂'
		elif [ $i -le 37 ]; then
			c='▃'
		elif [ $i -le 50 ]; then
			c='▄'
		elif [ $i -le 62 ]; then
			c='▅'
		elif [ $i -le 75 ]; then
			c='▆'
		elif [ $i -le 87 ]; then
			c='▇'
		else
			c='█'
		fi

		usage_text="$usage_text $c"
	done
	usage_text="$usage_text ]"

	temp="$(cat /sys/class/hwmon/hwmon1/temp1_input)"
	temp=$((temp/1000))
	echo "  $temp °C $usage_text"
}

function pretty_size {
	v=$1
	if [ $v -lt 256 ]; then
		str=$(printf '%d B' $v)
	elif [ $v -lt $((256*1024)) ]; then
		str=$(printf '%.1f K' `bc -l <<< "$v/1024"`)
	elif [ $v -lt $((256*1024*1024)) ]; then
		str=$(printf '%.1f M' `bc -l <<< "$v/(1024*1024)"`)
	else
		str=$(printf '%.1f G' `bc -l <<< "$v/(1024*1024*1024)"`)
	fi
	pad=$(printf '%*s' $((7 - ${#str})) '' | sed 's/ /_/g')
	printf "${pad}${str}"
}

function wifi {
	IFACE=wlo1
	if [ $(grep -c '<.*UP.*>' <<< `ip link show dev wlo1`) -eq 0 ]; then
		echo " Down"
		exit 0
	elif [ $(grep -c 'state DOWN' <<< `ip link show dev wlo1`) -ne 0 ]; then
		echo " Disconnected"
		exit 0
	fi

	TMPFILE=/tmp/.status.wifi
	iwconfig $IFACE > $TMPFILE
	SSID=`grep -o 'ESSID:".*"' $TMPFILE`
	SSID="${SSID:7:-1}"
	SIGNAL=`grep -o 'Signal level=-[0-9]* dBm' $TMPFILE`
	SIGNAL=`echo "2*(${SIGNAL:13:-4}+100)" | bc -l`
	if [ $SIGNAL -gt 99 ]; then
		SIGNAL=99
	elif [ $SIGNAL -lt 0 ]; then
		SIGNAL=0
	fi
	IP=`ip addr show dev wlo1 | grep -o 'inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*'`
	IP=${IP:5}
	rm -f $TMPFILE

	touch /tmp/.wifi_stats
	rx="$(cat /sys/class/net/wlo1/statistics/rx_bytes)"
	tx="$(cat /sys/class/net/wlo1/statistics/tx_bytes)"
	read old_rx old_tx < /tmp/.wifi_stats
	echo "$rx $tx" > /tmp/.wifi_stats
	drx=$((rx-old_rx))
	dtx=$((tx-old_tx))

	echo " ($SIGNAL% at $SSID) $IP  $(pretty_size $drx)  $(pretty_size $dtx)"
}

function ram {
	MEM=$(free | head -n 2 | tail -n 1 | awk '{printf $3+$5}')
	MEM=$((MEM/1024))
	echo "  ${MEM}M "
}

while true; do
	echo "$(ram) $(cpu)  $(wifi)  $(volume)  $(battery)  $(date_time) " || exit 1
	sleep 1& &>/dev/null
	SLEEPPID=$!
	wait
	SLEEPPID=''
done
