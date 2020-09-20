#!/bin/sh -ef

#
# game engine in posix shell.
#

### CORE FUNCTIONS ###

_term_resize() {
   termsize="$(stty size)"
   lines=${termsize%% *}
   columns=${termsize##* }
} && trap '_term_resize' WINCH

_term_init() {
   printf '[?1049h'
   _term_resize
   stty -echo -icanon
   printf '[?25l'
   clear
} && _term_init

_term_shutdown() {
   stty echo icanon
   printf '[?25h'
   clear
   printf '[?1049l'
   exit 0
} && trap '_term_shutdown' INT

#
# this engine uses 'eval' and simple variables to remember characters drawn.
# whenever a character is drawn, it is then added to this 'database'.
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

# sets one cell to what it is in the database
recover() { # <y> <x>
   buf="$(collide $1 $2)"
   if [ "$buf" ]; then
      fakedraw $1 $2 "$buf"
   else
      fakedraw $1 $2 " "
   fi
}

# visually clears an entire line
fakelineclear() { # <y>
   buf=""
   i=0
   while [ $i -le $columns ]; do
      buf="${buf} "
      i=$((i+1))
   done
   printf '[%d;H%s' $1 "$buf"
}

# remove a character
nullify() { # <y> <x>
   printf '[%d;%dH%s' $1 $2 " "
   eval "unset y${1}x${2}"
}

# draws the database on the screen
recover_all() {
   i=0
   while [ $i -le $lines ]; do
      ii=0
      while [ $ii -le $columns ]; do
         eval "printf '[%d;%dH%s' \"\${i}\" \"\${ii}\" \"\$y${i}x${ii}\""
         ii=$((ii+1))
      done
      i=$((i+1))
   done
}

debug() { # <string>
   printf '[H%s' "$*"
}

drawbox() { # <y1> <x1> <y2> <x2> <char>
   i=0 # top
   while [ $i -le $(($4-$2)) ]; do
      drawchar $1 $(($2+i)) "$5"
      i=$((i+1))
   done
   i=0 # bottom
   while [ $i -le $(($4-$2)) ]; do
      drawchar $3 $(($2+i)) "$5"
      i=$((i+1))
   done
   i=0 # left
   while [ $i -le $(($3-$1)) ]; do
      drawchar $(($1+i)) $2 "$5"
      i=$((i+1))
   done
   i=0 # right
   while [ $i -le $(($3-$1)) ]; do
      drawchar $(($1+i)) $4 "$5"
      i=$((i+1))
   done
}

gensquare() { # <y> <x> <y radius> <x radius>
   # returns: "<y1> <x1> <y2> <x2>"
   echo "$(($1-$3)) $(($2-$4)) $(($1+$3)) $(($2+$4))"
}

collide() { # <y> <x>
   # returns: <char>
   eval "echo \"\$y${1}x${2}\""
}

# scan for a specific character in a direction
hitscan() { # <y> <x> <direction> <character>
   # returns: "<y> <x>"
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

# scan for any character in a direction
hitscan_all() { # <y> <x> <direction>
   # returns: "<y> <x> <char>"
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

# in-game dev console
cmd() {
   fakedraw $((lines-1)) 1 ":"
   printf '[?25h'
   stty echo icanon
   read cmd
   stty -echo -icanon
   printf '[?25l'
   $cmd
   fakelineclear $((lines-1))
}
