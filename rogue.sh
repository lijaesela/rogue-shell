#!/bin/sh -ef

#
# once a recreation of rogue in pure POSIX shell.
# this is now a general playground for what has
# grown to be a surprisingly functional game engine.
#

_term_resize() {
   termsize="$(stty size)"
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

# print a character without adding it to the database
fakedraw() { # <y> <x> <char>
   printf '[%d;%dH%s' $1 $2 "$3"
}

# remove a character
nullify() { # <y> <x>
   printf '[%d;%dH%s' $1 $2 " "
   eval "unset y${1}x${2}"
}

debug() { # <string>
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

# returns what a position holds
collide() { # <y> <x>
   # returns: <char>
   eval "echo \"\$y${1}x${2}\""
}

# outputs args for drawbox
gensquare() { # <y> <x> <y radius> <x radius>
   # returns: <y1> <x1> <y2> <x2>
   echo "$(($1-$3)) $(($2-$4)) $(($1+$3)) $(($2+$4))"
}

# scan for a particular character
hitscan() { # <y> <x> <direction> <character>
   # returns: <y> <x>
   case $3 in
      left|h)
         i=$2
         while [ $i -ne 0 ]; do
            if [ "$(collide $1 $i)" = "$4" ]; then
               echo "$1 $i"
               return
            fi
            i=$((i-1))
         done
         ;;
      down|j)
         i=$1
         while [ $i -ne $lines ]; do
            if [ "$(collide $i $2)" = "$4" ]; then
               echo "$i $2"
               return
            fi
            true
            i=$((i+1))
         done
         ;;
      up|k)
         i=$1
         while [ $i -ne 0 ]; do
            if [ "$(collide $i $2)" = "$4" ]; then
               echo "$i $2"
               return
            fi
            i=$((i-1))
         done
         ;;
      right|l)
         i=$2
         while [ $i -ne $columns ]; do
            if [ "$(collide $1 $i)" = "$4" ]; then
               echo "$1 $i"
               return
            fi
            i=$((i+1))
         done
         ;;
   esac
}

# scan for any character
hitscan_all() { # <y> <x> <direction>
   # returns: <y> <x> <char>
   case $3 in
      left|h)
         i=$2
         while [ $i -ne 0 ]; do
            char="$(collide $1 $i)"
            if [ "$char" ]; then
               echo "$1 $i $char"
               return
            fi
            i=$((i-1))
         done
         ;;
      down|j)
         i=$1
         while [ $i -ne $lines ]; do
            char="$(collide $i $2)"
            if [ "$char" ]; then
               echo "$i $2 $char"
               return
            fi
            true
            i=$((i+1))
         done
         ;;
      up|k)
         i=$1
         while [ $i -ne 0 ]; do
            char="$(collide $i $2)"
            if [ "$char" ]; then
               echo "$i $2 $char"
               return
            fi
            i=$((i-1))
         done
         ;;
      right|l)
         i=$2
         while [ $i -ne $columns ]; do
            char="$(collide $1 $i)"
            if [ "$char" ]; then
               echo "$1 $i $char"
               return
            fi
            i=$((i+1))
         done
         ;;
   esac
}

### MAIN ###

drawbox $(gensquare $((lines/2)) $((columns/2)) 6 12) "#"
drawbox $(gensquare $((lines/2)) $((columns/2)) 7 13) "#"
drawbox $(gensquare $((lines/3)) $((columns/3)) 4 8) "#"
drawbox $(gensquare $((lines/3*2)) $((columns/3*2)) 4 8) "#"

player_y=$((lines/2))
player_x=$((columns/2))

while true; do

   # draw player
   fakedraw $player_y $player_x "$"

   # grab input
   key=$(dd bs=1 count=1 2>/dev/null)

   # undraw player, redraw anything that player trampled
   trample="$(collide $player_y $player_x)"
   if [ "$trample" ]; then
      fakedraw $player_y $player_x "$trample"
   else
      fakedraw $player_y $player_x " "
   fi

   # store old position
   player_y_old=$player_y
   player_x_old=$player_x

   # compute input
   case $key in
      q) _term_shutdown;;

      # moving
      h) player_x=$((player_x-1));;
      j) player_y=$((player_y+1));;
      k) player_y=$((player_y-1));;
      l) player_x=$((player_x+1));;

      # shooting
      s) fakedraw $player_y $player_x "#"
         key=$(dd bs=1 count=1 2>/dev/null)
         dst="$(hitscan_all $player_y $player_x $key)"
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
   elif [ $player_x -ge $columns ]; then
      player_x=$columns
   elif [ $player_x -le 0 ]; then
      player_x=1
   fi
done
