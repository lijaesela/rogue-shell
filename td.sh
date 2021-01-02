#!/bin/sh -f

#
# tower defense / puzzle
# all in 100% POSIX shell
# what have I gotten myself into
# aauaughagh fuckc no my object orientation
# find a way to make this engaging
# find a way to easily store different "levels"
#

. ./core.sh
term_init

# init map
map="tdmap"
smart_source "$map"
recover_all

# trying to come close to having "objects"
move() {
    # <char> <y offset (int)> <x offset (int)>
    # [replace with (char)] [keep old? (anything for yes)]

    # find chars
    chars="$(grepfind "$1")"
    # exit if nothing is found
    [ "$chars" ] || return
    for i in $chars; do
	# strip grepfind results
	ch_y="${i#y}"
	ch_y="${ch_y%%x*}"
	ch_x="${i##*x}"
	ch_x="${ch_x%%=*}"
	# remove old char/position (unless told not to)
	[ "$5" ] || nullify "$ch_y" "$ch_x"
	# calculate didsplacement
	ch_y="$((ch_y + $2))"
	ch_x="$((ch_x + $3))"
	# check for bends in the track
	buf="$(collide $ch_y $ch_x)"
	case "$buf" in
	    "^")
		ch_y="$((ch_y - 1))"
		char="u"
		;;
	    "V")
		ch_y="$((ch_y + 1))"
		char="d"
		;;
	    "<")
		ch_x="$((ch_x - 1))"
		char="l"
		;;
	    ">")
		ch_x="$((ch_x + 1))"
		char="r"
		;;
	    "G")
		lives=$((lives - 1))
		if [ $lives = 0 ]; then
		    term_shutdown
		fi
		return
		;;
	    *)
		if [ "$4" ]; then
		    char="$4"
		else
		    char="$1"
		fi
		;;
	esac
	drawchar "$ch_y" "$ch_x" "$char"
    done
}

# initial game state
p_y=10
p_x=20
lives=5
tg=0

# move things
while true; do

    # control player
    fakedraw $p_y $p_x "$"
    getkey input
    recover $p_y $p_x
    case $input in
	h) p_x=$((p_x-1));;
	j) p_y=$((p_y+1));;
	k) p_y=$((p_y-1));;
	l) p_x=$((p_x+1));;
	f) drawchar $p_y $p_x "Q";;
	q) term_shutdown;;
    esac

    # move enemies
    # do two passes over all directions to prevent double moving
    move "U" -1 0
    move "D" 1 0
    move "L" 0 -1
    move "R" 0 1
    move "u" 0 0 "U"
    move "d" 0 0 "D"
    move "l" 0 0 "L"
    move "r" 0 0 "R"

    # cycle turrets
    # (two passes again)
    move "Q" 0 0 "="
    move "3" 0 0 "-"
    move "2" 0 0 "+"
    move "1" 0 0 "_"
    move "=" 0 0 "3"
    move "-" 0 0 "2"
    move "+" 0 0 "1"
    move "_" 0 0 "Q"

    # spawn enemies every 4 ticks
    if [ $tg = 3 ]; then
	tg=0
	move "S" 1 0 "D" 1
    else
	tg=$((tg+1))
    fi

done
