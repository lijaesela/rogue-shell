#!/bin/sh -ef

#
# tower defense in shell
# what have I gotten myself into
# aauaughagh fuckc no my object orientation
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


move() { # <char> <y disp.> <x disp.>
    # find chars
    chars="$(grepfind "$1")"
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
	# new position
	drawchar "$ch_y" "$ch_x" "$1"
    done
}

# spawn Q at S
spawn "S" "Q" 1 0
getkey void

# move Q down by 1
move "Q" 1 0
getkey void

# c e a s e
term_shutdown
