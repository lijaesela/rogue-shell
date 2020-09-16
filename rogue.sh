#!/bin/sh -e

#
# recreation of rogue in pure POSIX shell.
#

_term_resize() {
   termsize="`stty size`"
   lines=${termsize%% *}
   columns=${termsize##* }
} && trap '_term_resize' WINCH

_term_init() {
   _term_resize
   stty -echo -icanon
   printf '[?25l'
   clear
} && _term_init

_term_shutdown() {
   stty echo icanon
   printf '[?25h'
   clear
   exit 0
} && trap '_term_shutdown' INT

### FUNCTIONS ###

#
# rogue-shell uses 'eval' and simple variables to track characters.
# whenever a character is drawn, it is added to this database.
# this is how collision is done.
#

drawchar() { # <y> <x> <char>
   printf '[%d;%dH%s' $1 $2 "$3"
   eval "y${1}x${2}=\"${3}\""
}

toptest() { # <string>
   printf '[H%s' "$*"
}

drawbox() { # <y1> <x1> <y2> <x2> <char>

   # top
   i=0
   while [ $i -le $(($4-$2)) ]; do
      printf '[%d;%dH%s' $1 $(($2+i)) "$5"
      eval "y${1}x$(($2+i))=\"${5}\""
      i=$((i+1))
   done

   # bottom
   i=0
   while [ $i -le $(($4-$2)) ]; do
      printf '[%d;%dH%s' $3 $(($2+i)) "$5"
      eval "y${3}x$(($2+i))=\"${5}\""
      i=$((i+1))
   done

   # left
   i=0
   while [ $i -le $(($3-$1)) ]; do
      printf '[%d;%dH%s' $(($1+i)) $2 "$5"
      eval "y$(($1+i))x${2}=\"${5}\""
      i=$((i+1))
   done

   # right
   i=0
   while [ $i -le $(($3-$1)) ]; do
      printf '[%d;%dH%s' $(($1+i)) $4 "$5"
      eval "y$(($1+i))x${4}=\"${5}\""
      i=$((i+1))
   done
}

playerbounds() {
   eval "echo \"\$y${player_y}x${player_x}\""
}

gensquare() { # <y> <x> <y radius> <x radius>
   echo "$(($1-$3)) $(($2-$4)) $(($1+$3)) $(($2+$4))"
}

### MAIN ###

drawbox `gensquare $((lines/2)) $((columns/2)) 6 12` "█"
drawbox `gensquare $((lines/3)) $((columns/3)) 4 8` "█"
drawbox `gensquare $((lines/3*2)) $((columns/3*2)) 4 8` "█"

player_y=$((lines/2))
player_x=$((columns/2))

while true; do

   # draw player
   drawchar $player_y $player_x "$"

   # grab input
   key=`dd bs=1 count=1 2>/dev/null`

   # undraw player
   drawchar $player_y $player_x " "

   # store old position
   player_y_old=$player_y
   player_x_old=$player_x

   # compute input
   case $key in
      h) player_x=$((player_x-1));;
      j) player_y=$((player_y+1));;
      k) player_y=$((player_y-1));;
      l) player_x=$((player_x+1));;
      f) drawbox `gensquare $player_y $player_x 1 1` " ";;
      q) _term_shutdown;;
   esac

   # collision with any unicode character
   case "`playerbounds`" in
      █)
         player_y=$player_y_old
         player_x=$player_x_old
         ;;
      ""|" ")
         ;;
   esac

   # collision with terminal
   if [ $player_y -ge $lines ]; then
      player_y=$lines
   elif [ $player_y -le 0 ]; then
      player_y=1
   elif [ $player_x -ge $columns ]; then
      player_x=$columns
   elif [ $player_x -le 0 ]; then
      player_x=1
   fi
done
