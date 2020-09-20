#!/bin/sh -ef

#
# example game
# vim keys to move
# s + vim keys to shoot at walls
#

. ./core.sh
term_init

# set stage
drawbox $(gensquare $((lines/2)) $((columns/2)) 6 12) "#"
drawbox $(gensquare $((lines/2)) $((columns/2)) 7 13) "#"
drawbox $(gensquare $((lines/3)) $((columns/3)) 4 8) "#"
drawbox $(gensquare $((lines/3*2)) $((columns/3*2)) 4 8) "#"
player_y=$((lines/2))
player_x=$((columns/2))

# main
while true; do

   # draw player
   fakedraw $player_y $player_x "$"

   # grab input
   getkey key

   # undraw player
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
      s) fakedraw $player_y $player_x "#"
         key=$(dd bs=1 count=1 2>/dev/null)
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
   esac

   # collision with terminal
   if [ $player_y -ge $lines ]; then
      player_y=$lines
   elif [ $player_y -le 0 ]; then
      player_y=1
   fi
   if [ $player_x -ge $columns ]; then
      player_x=$columns
   elif [ $player_x -le 0 ]; then
      player_x=1
   fi
done
