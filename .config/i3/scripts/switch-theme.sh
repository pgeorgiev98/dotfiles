#!/bin/bash

DARK_WALLPAPER=$HOME/.config/i3/dark.png
DARK_ARGS=--bg-tile
LIGHT_WALLPAPER=$HOME/.config/i3/light.png
LIGHT_ARGS=--bg-tile

# Check what the current theme is and set the new one
bg=`xrdb -q | grep '\*background:' | tail -n 1 | awk '{print $2}'`
NEW_THEME=dark
if [ `echo 'ibase=16;' $(echo ${bg:1:1} | awk '{print toupper($1)}') | bc` -lt 8 ]; then
	NEW_THEME=light
fi

echo "Switching to $NEW_THEME theme"

# Set the new theme background and
# merge with the .Xdefaults of the new theme
if [ "$NEW_THEME" == "dark" ]; then
	feh $DARK_WALLPAPER $DARK_ARGS
	xrdb -merge $HOME/.Xdefaults.dark
else
	feh $LIGHT_WALLPAPER $LIGHT_ARGS
	xrdb -merge $HOME/.Xdefaults.light
fi

# Change background in vim configuration
sed -i "s/^set background=.*$/set background=$NEW_THEME/g" $HOME/.vimrc

# Reload i3
i3-msg reload

# Reload Dunst
pkill dunst


# Read the new colors

fg=`xrdb -q | grep '\*foreground:' | tail -n 1 | awk '{print $2}'`
bg=`xrdb -q | grep '\*background:' | tail -n 1 | awk '{print $2}'`

declare -a colors
for i in `seq 0 15`; do
	colors[$i]=`xrdb -q | grep "\*color$i:" | tail -n 1 | awk '{print $2}'`
done


# Change the terminal colors

TMP=/tmp/.switch-theme.tmp

printf "\033]10;${fg}\007" >> $TMP
printf "\033]11;${bg}\007" > $TMP
printf "\033]39;${fg}\007" > $TMP
printf "\033]49;${bg}\007" >> $TMP
printf "\033]708;[95]${bg}\007" >> $TMP
printf "\033]11;[95]${bg}\007" >> $TMP

for i in `seq 0 15`; do
	printf "\033]4;$i;${colors[i]}\007" >> $TMP
done

for i in `ls /dev/pts/ | grep -E '[0-9]+'`; do
	cat $TMP > /dev/pts/$i
done

rm -f $TMP
