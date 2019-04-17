#!/bin/bash

BASE01='586e75'
BASE0='839496'

RED='dc322f'
BLUE='268bd2'

BACKGROUND='fdf6e3'
FOREGROUND='002b36'

INSIDEVER=$BLUE
INSIDEWRONG=$RED
INSIDE=$BACKGROUND
RINGVER=$BLUE
RINGWRONG=$RED
RING=$BASE01
LINE=$BACKGROUND
KEYHLCOLOR=$FOREGROUND
BSHL=$RED
SEPARATOR=$BACKGROUND
VERIF=$FOREGROUND
WRONG=$FOREGROUND
LAYOUT=$FOREGROUND
TIME=$FOREGROUND
DATE=$FOREGROUND

i3lock -e --clock --keylayout 0 \
	-c $BACKGROUND \
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
