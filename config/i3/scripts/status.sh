#!/bin/bash

ICON_SPACING=9

SLEEPPID=''

trap 'if [ ! -z $SLEEPPID ]; then kill -SIGINT $SLEEPPID; fi' SIGUSR1

CPU_STATS_OLD_FILE=$(mktemp)
CPU_STATS_NEW_FILE=$(mktemp)
STATUS_WIFI_FILE=$(mktemp)
WIFI_STATS_FILE=$(mktemp)

trap "rm -f $CPU_STATS_OLD_FILE $CPU_STATS_NEW_FILE $STATUS_WIFI_FILE $WIFI_STATS_FILE" INT TERM EXIT

function get_cpu_temperature_file {
	for i in /sys/class/hwmon/hwmon*/temp*_label; do
		if grep package $i -i &> /dev/null; then
			f=$(sed 's/label$/input/' <<< $i)
			if [ -r $f ]; then
				echo $f
				return
			fi
		fi
	done
}
cpu_temperature_file=$(get_cpu_temperature_file)

function date_time {
	echo "{\"name\":\"date\",\"full_text\":\" $(date +%Y-%m-%d)\"},"
	echo "{\"name\":\"time\",\"full_text\":\" $(date +%H:%M:%S)\"}"
}

function battery {
	color=''
	battery_level="$(cat /sys/class/power_supply/BAT0/capacity)"
	if [ $? -eq 0 ]; then
		status="$(cat /sys/class/power_supply/BAT0/status)"
		if [ "$battery_level" -lt 15 ]; then
			battery_icon=''
			color=${COLOR_RED}
		elif [ "$battery_level" -lt 40 ]; then
			battery_icon=''
			color=${COLOR_YELLOW}
		elif [ "$battery_level" -lt 65 ]; then
			battery_icon=''
			color=${COLOR_YELLOW}
		elif [ "$battery_level" -lt 90 ]; then
			battery_icon=''
			color=${COLOR_GREEN}
		else
			battery_icon=''
			color=${COLOR_GREEN}
		fi

		if [ "$status" != "Discharging" ]; then
			color=${COLOR_BLUE}
		fi

		battery_level="$battery_level%"
	else
		battery_icon=''
		battery_level="N/A"
		color=${COLOR_RED}
	fi

	if [ -n "$color" ]; then
		color=",\"color\":\"$color\""
	fi

	echo "{\"name\":\"battery_icon\",\"full_text\":\"$battery_icon\",\"separator\":false,\"separator_block_width\":${ICON_SPACING}${color}},"
	echo "{\"name\":\"battery_text\",\"full_text\":\"$battery_level\",\"min_width\":\"100%\",\"align\":\"right\"${color}}"
}

function volume {
	color=''
	sink=$(pactl list short sinks | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,' | head -n 1 )
	level=$(pactl list sinks | grep '^[[:space:]]Volume:' | head -n $(( $sink+ 1 )) | tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,' )
	muted=$(pactl list sinks | grep '^[[:space:]]Mute:' | head -n $((sink+1)) | tail -n 1 | awk '{printf $2}')
	volume_icon=''
	if [ "$muted" == "yes" ]; then
		volume_icon=''
	elif [ "$level" -lt 34 ]; then
		volume_icon=''
	elif [ "$level" -lt 67 ]; then
		volume_icon=''
	else
		volume_icon=''
	fi

	if [ "$level" -gt 100 ]; then
		color=",\"color\":\"${COLOR_RED}\""
	fi

	echo "{\"name\":\"volume_icon\",\"full_text\":\"$volume_icon\",\"min_width\":\"\",\"separator\":false,\"separator_block_width\":${ICON_SPACING}${color}},"
	echo "{\"name\":\"volume_text\",\"full_text\":\"$level%\",\"min_width\":\"100%\",\"align\":\"right\"${color}}"
}

function cpu {
	cpu_usage=[]
	grep '^cpu[0-9]' /proc/stat > $CPU_STATS_NEW_FILE
	i=0
	lines_count=`wc -l $CPU_STATS_NEW_FILE | awk '{print $1}'`
	for i in `seq 0 $((lines_count-1))`; do 
		read -r -a stats <<< `head -n $((i+1)) $CPU_STATS_NEW_FILE | tail -n 1`
		read -r -a old_stats <<< `head -n $((i+1)) $CPU_STATS_OLD_FILE | tail -n 1`
		s=(${stats[@]})
		for j in `seq 1 8`; do s[j]=$((s[j]-old_stats[j])); done
		total=$((s[1]+s[2]+s[3]+s[4]+s[5]+s[6]+s[7]+s[8]))
		idle=$((s[4]+s[5]))

		cpu_usage[i]=$(( 100 - (100*idle) / total ))
	done
	mv $CPU_STATS_NEW_FILE $CPU_STATS_OLD_FILE &> /dev/null

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

	temp_color=''
	temp=
	if [ -n "$cpu_temperature_file" ]; then
		temp=$(cat $cpu_temperature_file)
	fi

	if [ -z "$temp" ]; then
		temp='N/A'
		temp_color=",\"color\":\"$COLOR_RED\""
	else
		temp="$((temp/1000)) °C"

		if [ "$temp" -ge 80 ]; then
			temp_color=",\"color\":\"$COLOR_RED\""
		elif [ "$temp" -ge 65 ]; then
			temp_color=",\"color\":\"$COLOR_YELLOW\""
		fi
	fi

	maxfreq=0
	for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
		f=`cat $i`
		if [ $f -gt $maxfreq ]; then
			maxfreq=$f
		fi
	done
	freq_color=''
	if [ $maxfreq -gt 2900000 ]; then
		freq_color=",\"color\":\"$COLOR_RED\""
	elif [ $maxfreq -gt 1400000 ]; then
		freq_color=",\"color\":\"$COLOR_YELLOW\""
	fi
	maxfreq=$(echo "scale=1; f=$maxfreq/1000000; if(f<1) print 0; f" | bc)

	echo "{\"name\":\"cpu_temp_icon\",\"full_text\":\"\",\"separator\":false,\"separator_block_width\":${ICON_SPACING}${temp_color}},"
	echo "{\"name\":\"cpu_temp_text\",\"full_text\":\"$temp\",\"min_width\":\"100 °C\",\"align\":\"right\"${temp_color}},"

	echo "{\"name\":\"cpu_freq_icon\",\"full_text\":\"\",\"separator\":false,\"separator_block_width\":${ICON_SPACING}${freq_color}},"
	echo "{\"name\":\"cpu_freq_text\",\"full_text\":\"$maxfreq GHz\",\"min_width\":\"1.0 GHz\",\"align\":\"right\"${freq_color}},"

	echo "{\"name\":\"cpu_usage_text\",\"full_text\":\"$usage_text\"}"
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
	printf "${str}"
}

function wifi {
	IFACE=wlo1
	if [ $(grep -c '<.*UP.*>' <<< `ip link show dev wlo1`) -eq 0 ]; then
		echo "{\"name\":\"wifi\",\"full_text\":\" Down\",\"color\":\"$COLOR_RED\"}"
		exit 0
	elif [ $(grep -c 'state DOWN' <<< `ip link show dev wlo1`) -ne 0 ]; then
		echo "{\"name\":\"wifi\",\"full_text\":\" Disconnected\",\"color\":\"$COLOR_RED\"}"
		exit 0
	fi

	iwconfig $IFACE > $STATUS_WIFI_FILE
	SSID=`grep -o 'ESSID:".*"' $STATUS_WIFI_FILE`
	SSID="${SSID:7:-1}"
	IP=`ip addr show dev wlo1 | grep -o 'inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*'`
	IP=${IP:5}

	rx="$(cat /sys/class/net/wlo1/statistics/rx_bytes)"
	tx="$(cat /sys/class/net/wlo1/statistics/tx_bytes)"
	read old_rx old_tx < $WIFI_STATS_FILE
	echo "$rx $tx" > $WIFI_STATS_FILE
	drx=$((rx-old_rx))
	dtx=$((tx-old_tx))

	no_sep="\"separator\":false,\"separator_block_width\":${ICON_SPACING}"

	tx_color=''
	rx_color=''

	if [ $dtx -gt $((1*1024*1024)) ]; then
		tx_color=",\"color\":\"$COLOR_RED\""
	elif [ $dtx -gt $((128*1024)) ]; then
		tx_color=",\"color\":\"$COLOR_YELLOW\""
	fi

	if [ $drx -gt $((1*1024*1024)) ]; then
		rx_color=",\"color\":\"$COLOR_RED\""
	elif [ $drx -gt $((128*1024)) ]; then
		rx_color=",\"color\":\"$COLOR_YELLOW\""
	fi

	echo "{\"name\":\"wifi_name\",\"full_text\":\" $SSID\",$no_sep},"
	echo "{\"name\":\"wifi_ip\",\"full_text\":\"$IP\",$no_sep},"
	echo "{\"name\":\"wifi_down_icon\",\"full_text\":\"\",$no_sep$rx_color},"
	echo "{\"name\":\"wifi_down_text\",\"full_text\":\"$(pretty_size $drx)\",\"min_width\":\"999.9 M\",\"align\":\"right\",$no_sep$rx_color},"
	echo "{\"name\":\"wifi_up_icon\",\"full_text\":\"\",$no_sep$tx_color},"
	echo "{\"name\":\"wifi_up_text\",\"full_text\":\"$(pretty_size $dtx)\",\"min_width\":\"999.9 M\",\"align\":\"right\"$tx_color}"
}

function ram {
	used=$(free | head -n 2 | tail -n 1 | awk '{printf $3+$5}')
	total=$(free | head -n 2 | tail -n 1 | awk '{printf $2}')
	if [ $(bc <<< "$used > $total * 0.8") -ne 0 ]; then
		color=",\"color\":\"$COLOR_RED\""
	else
		color=''
	fi
	used=$((used/1024))
	total=$((total/1024))
	echo "{\"name\":\"ram_icon\",\"full_text\":\"\",\"separator\":false,\"separator_block_width\":${ICON_SPACING}${color}},"
	echo "{\"name\":\"ram_text\",\"full_text\":\"${used}M\",\"min_width\":\"${total}M\",\"align\":\"right\"${color}}"
}

echo '{ "version": 1 }'
echo '['
echo '[]'
while true; do
	COLOR_FG=$(     xrdb -q | grep -m 1 foreground: | awk '{print $2}')
	COLOR_RED=$(    xrdb -q | grep -m 1 color1:     | awk '{print $2}')
	COLOR_GREEN=$(  xrdb -q | grep -m 1 color2:     | awk '{print $2}')
	COLOR_YELLOW=$( xrdb -q | grep -m 1 color3:     | awk '{print $2}')
	COLOR_BLUE=$(   xrdb -q | grep -m 1 color4:     | awk '{print $2}')
	COLOR_MAGENTA=$(xrdb -q | grep -m 1 color5:     | awk '{print $2}')
	COLOR_CYAN=$(   xrdb -q | grep -m 1 color6:     | awk '{print $2}')

	echo ",[$(ram),$(cpu),$(wifi),$(volume),$(battery),$(date_time)]" || exit 1
	sleep 1& &>/dev/null
	SLEEPPID=$!
	wait
	SLEEPPID=''
done
