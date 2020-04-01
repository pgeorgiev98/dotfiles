#!/bin/bash

DIR=~/.config/i3/colorschemes

# Convert from snake_case to Camel Case With Spaces
function format() {
	read str
	out=
	for i in ${str//_/ }; do
		out="$out ${i^}"
	done
	echo $out
}

# The opposite of format()
function parse() {
	read str
	str=${str,,}
	echo ${str// /_}
}

# Open colorschemes menu
option=$(for i in $DIR/*; do
	basename $i | format
done | rofi -dmenu -i -p "Select colorscheme:" -a 0 -no-custom | parse)

if [ -z "$option" ]; then
	exit
fi

# Apply the changes to Xdefaults
file_path=$DIR/$option
sed -i "s/^#include .*\$/#include \\\"${file_path//\//\\\/}\\\"/" ~/.Xdefaults

# Load the new Xdefaults
xrdb ~/.Xdefaults

# Reload i3
i3-msg reload

if grep -i dark <<< $option &> /dev/null; then
	echo background to dark
	sed -i 's/^set background=light$/set background=dark/' ~/.vimrc
else
	echo background to light
	sed -i 's/^set background=dark$/set background=light/' ~/.vimrc
fi

# Read the new colors

fg=`xrdb -q | grep '\*foreground:' | tail -n 1 | awk '{print $2}'`
bg=`xrdb -q | grep '\*background:' | tail -n 1 | awk '{print $2}'`
pr=`xrdb -q | grep 'primary:' | tail -n 1 | awk '{print $2}'`
cursor=`xrdb -q | grep '\*cursorColor:' | tail -n 1 | awk '{print $2}'`

declare -a colors
for i in `seq 0 15`; do
	colors[$i]=`xrdb -q | grep "\*color$i:" | tail -n 1 | awk '{print $2}'`
done

# Update dunstrc and restart dunst
sed "s/background_urgency_low/\"$bg\"/g; s/background_urgency_normal/\"$bg\"/g; s/background_urgency_critical/\"${color[0]}\"/g; s/foreground_urgency_low/\"$fg\"/g; s/foreground_urgency_normal/\"$fg\"/g; s/foreground_urgency_critical/\"$bg\"/g; s/frame_color_urgency_low/\"$pr\"/g; s/frame_color_urgency_normal/\"$pr\"/g; s/frame_color_urgency_critical/\"$pr\"/g" ~/.config/i3/scripts/switch-theme/dunstrc-template > ~/.config/dunst/dunstrc
pkill dunst
dunst& &> /dev/null
disown

# Set the new background color
f=~/.config/i3/background.png
convert $f -fill "${pr}" -draw "color 0,0 point" $f
feh --bg-tile $f

# Change the terminal colors

TMP=$(mktemp)
trap "rm -f $TMP" EXIT

printf "\033]10;${fg}\007" >> $TMP
printf "\033]11;${bg}\007" >> $TMP
printf "\033]12;${cursor}\007" >> $TMP
printf "\033]39;${fg}\007" >> $TMP
printf "\033]49;${bg}\007" >> $TMP
printf "\033]708;${bg}\007" >> $TMP

for i in `seq 0 15`; do
	printf "\033]4;$i;${colors[i]}\007" >> $TMP
done

for i in `ls /dev/pts/ | grep -E '[0-9]+'`; do
	cat $TMP > /dev/pts/$i
done
