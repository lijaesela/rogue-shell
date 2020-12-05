#!/bin/sh -ef
#shellcheck disable=SC2086
#shellcheck disable=SC2046

#
# benchmark for comparing shell performance
# based on example game, but without infinite loop
#

. ./core.sh
term_init

# set stage
if [ "$1" ]; then
   level="$1"
else
   level="save"
fi
smart_source $level
recover_all

player_y=1
player_x=1

# main
for key in j j l l l l l l l l l l l l l l j j j j l l l l l l l j j j l l l l j j j l l l l j j j j l l l l
do
   fakedraw $player_y $player_x "$"
   recover $player_y $player_x

   # store old position
   player_y_old=$player_y
   player_x_old=$player_x

   # compute input
   case $key in
      h) player_x=$((player_x-1));;
      j) player_y=$((player_y+1));;
      k) player_y=$((player_y-1));;
      l) player_x=$((player_x+1));;
   esac

   # collision with any character
   case "$(collide $player_y $player_x)" in
      "#")
         player_y=$player_y_old
         player_x=$player_x_old
         ;;
      "v")
         dst="$(hitscan $player_y $player_x down "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      "^")
         dst="$(hitscan $player_y $player_x up "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      "<")
         dst="$(hitscan $player_y $player_x left "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      ">")
         dst="$(hitscan $player_y $player_x right "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
   esac
done

term_shutdown
