#!/bin/sh -ef
# shellcheck disable=SC2086
# shellcheck disable=SC2046

#
# example game
# 'hjkl' to move
# 's', then 'hjkl' to shoot
#
# '#' is a wall
# 'V ^ < >' move the player in the directions they point
#

. ./core.sh
term_init

# set stage
. ./save.sh
recover_all

# find 's'
spawn="$(grepfind "s")"
# set player at 's'
spawn_y="${spawn#y}"
spawn_y="${spawn_y%%x*}"
player_y=$spawn_y
spawn_x="${spawn##*x}"
spawn_x="${spawn_x%%=*}"
player_x=$spawn_x
# delete 's'
nullify $spawn_y $spawn_x

# main
while true; do
   fakedraw $player_y $player_x "$"
   getkey key
   recover $player_y $player_x

   # store old position
   player_y_old=$player_y
   player_x_old=$player_x

   # compute input
   case $key in
      q) term_shutdown;;
      :) cmd;;

      # moving
      h) player_x=$((player_x-1));;
      j) player_y=$((player_y+1));;
      k) player_y=$((player_y-1));;
      l) player_x=$((player_x+1));;

      # shooting
      s) fakedraw $player_y $player_x "%"
         getkey key
         dst="$(hitscan_any $player_y $player_x $key)"
         case "${dst##* }" in
            "#") drawchar ${dst% ?} "=";;
            "=") drawchar ${dst% ?} "+";;
            "+") drawchar ${dst% ?} "-";;
            "-") nullify ${dst% ?};;
         esac;;
   esac

   # collision with any character
   case "$(collide $player_y $player_x)" in
      "#"|"="|"+"|"-")
         player_y=$player_y_old
         player_x=$player_x_old
         ;;
      V)
         dst="$(hitscan $player_y $player_x down "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      ^)
         dst="$(hitscan $player_y $player_x up "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      <)
         dst="$(hitscan $player_y $player_x left "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
      >)
         dst="$(hitscan $player_y $player_x right "")"
         player_y=${dst%% *}
         player_x=${dst##* }
         ;;
   esac
done
