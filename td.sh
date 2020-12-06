#!/bin/sh -f

#
# tower defense / puzzle
# all in 100% POSIX shell
# what have I gotten myself into
# aauaughagh fuckc no my object orientation
# STOP USING EXPR BRUH (remember to change that)
# find a way to make this engaging
# find a way to easily store different "levels"
#

. ./core.sh
term_init

map="tdmap"
smart_source tdmap
recover_all

spawn() { # <spawnpoint> <char> <y displacement> <x displacement>
    # find the point
    spawn="$(grepfind "$1")"
    # cut y out
    sp_y="${spawn#y}"
    sp_y="${sp_y%%x*}"
    # cut x out
    sp_x="${spawn##*x}"
    sp_x="${sp_x%%=*}"
    # add displacement
    sp_y="$(expr $sp_y + $3)"
    sp_x="$(expr $sp_x + $4)"
    # spawn it
    drawchar "$sp_y" "$sp_x" "$2"
    # I'd love to make this work for multiple spawnpoints
}


move() { # <char> <y disp.> <x disp.> <<set of chars for directions>> <replace?>
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
	# remove old char/position
	nullify "$ch_y" "$ch_x"
	# calculate didsplacement
	ch_y="$(expr $ch_y + $2)"
	ch_x="$(expr $ch_x + $3)"
	# check for bends in the track
	buf="$(collide $ch_y $ch_x)"
	case "$buf" in
	    "^")
		ch_y="$(expr $ch_y - 1)"
		char="$4"
		;;
	    "V")
		ch_y="$(expr $ch_y + 1)"
		char="$5"
		;;
	    "<")
		ch_x="$(expr $ch_x - 1)"
		char="$6"
		;;
	    ">")
		ch_x="$(expr $ch_x + 1)"
		char="$7"
		;;
	    "G")
		# trigger some game ending event
		return
		;;
	    *)
		if [ "$8" ]; then
		    char="$8"
		else
		    char="$1"
		fi
		;;
	esac
	drawchar "$ch_y" "$ch_x" "$char"
    done
}

# spawn D at S
spawn "S" "D" 1 0

# initial game state
p_y=10
p_x=20

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
    move "U" -1 0 "u" "d" "l" "r"
    move "D" 1 0  "u" "d" "l" "r"
    move "L" 0 -1 "u" "d" "l" "r"
    move "R" 0 1  "u" "d" "l" "r"
    move "u" 0 0 "U" "D" "L" "R" "U"
    move "d" 0 0 "U" "D" "L" "R" "D"
    move "l" 0 0 "U" "D" "L" "R" "L"
    move "r" 0 0 "U" "D" "L" "R" "R"

    # cycle turrets
    # (two passes again)
    move "Q" 0 0 "U" "D" "L" "R" "="
    move "3" 0 0 "U" "D" "L" "R" "-"
    move "2" 0 0 "U" "D" "L" "R" "+"
    move "1" 0 0 "U" "D" "L" "R" "_"
    move "=" 0 0 "U" "D" "L" "R" "3"
    move "-" 0 0 "U" "D" "L" "R" "2"
    move "+" 0 0 "U" "D" "L" "R" "1"
    move "_" 0 0 "U" "D" "L" "R" "Q"

done
