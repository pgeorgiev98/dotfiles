#!/bin/bash

BG=`xrdb -q | grep '^\*background:' | cut -f2 -d# | tr A-Z a-z`
FG=`xrdb -q | grep '^\*foreground:' | cut -f2 -d# | tr A-Z a-z`
RED=`xrdb -q | grep '^\*color0:' | cut -f2 -d# | tr A-Z a-z`
AC=`xrdb -q | grep '^accent:' | cut -f2 -d# | tr A-Z a-z`
PR=`xrdb -q | grep '^primary:' | cut -f2 -d# | tr A-Z a-z`

INSIDEVER=$AC
INSIDEWRONG=$RED
INSIDE=$BG
RINGVER=$AC
RINGWRONG=$RED
RING=$PR
LINE=$BG
KEYHLCOLOR=$FG
BSHL=$RED
SEPARATOR=$BG
VERIF=$FG
WRONG=$FG
LAYOUT=$FG
TIME=$FG
DATE=$FG

i3lock -e --clock --keylayout 0 \
	-c $BG \
	"--insidevercolor=${INSIDEVER}ff" \
	"--insidewrongcolor=${INSIDEWRONG}ff" \
	"--insidecolor=${INSIDE}ff" \
	"--ringvercolor=${RINGVER}ff" \
	"--ringwrongcolor=${RINGWRONG}ff" \
	"--ringcolor=${RING}ff" \
	"--linecolor=${LINE}ff" \
	"--keyhlcolor=${KEYHLCOLOR}ff" \
	"--bshlcolor=${BSHL}ff" \
	"--separatorcolor=${SEPARATOR}ff" \
	"--verifcolor=${VERIF}ff" \
	"--wrongcolor=${WRONG}ff" \
	"--layoutcolor=${LAYOUT}ff" \
	"--timecolor=${TIME}ff" \
	"--datecolor=${DATE}ff"
