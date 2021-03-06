#!/bin/sh -ef
#shellcheck disable=SC2086
#shellcheck disable=SC2046

#
# game engine in posix shell
# somewhat similar to ncurses in its graphical functionality
#

### TERMINAL ###

# needs to be run at the beginning of every game
# must be called manually
term_init() {
   term_resize
   stty -echo -icanon
   clear; printf '[?25l[H'
   trap 'term_shutdown' INT
   trap 'term_resize' WINCH
}

# needs to be run at the end of every game
# can be called manually, but also runs when you hit C-c
term_shutdown() { # [message]
   stty echo icanon
   clear; printf '[?25h[H'
   [ "$1" ] && echo "$1"
   exit
}

# gets window dimensions
# runs with 'term_init' and with window resize
term_resize() {
   termsize="$(stty size)"
   lines=${termsize%% *}
   columns=${termsize##* }
}

### CORE FUNCTIONS ###

#
# this engine uses 'eval' and simple variables to remember characters.
# whenever a character is drawn, it is then added to this 'database'.
# for example: if 'drawchar' is used to place '%' at row 4 column 4,
# the string '%' is assigned to the variable 'y4x4'.
#

# pause and get input from the keyboard
# uses dd for posix, read for bash
if [ "$BASH_VERSION" ]; then
    getkey() { # <var>
	read -n1 ${1}
    }
else
    getkey() { # <var>
	eval "${1}=\$(dd bs=1 count=1 2>/dev/null)"
    }
fi

# add a character
drawchar() { # <y> <x> <char>
   printf '[%d;%dH%s' $1 $2 "$3"
   eval "y${1}x${2}=\"${3}\""
}

# print a character without adding it to the database
fakedraw() { # <y> <x> <char>
   printf '[%d;%dH%s' $1 $2 "$3"
}

# visually clears an entire line
fakelineclear() { # <y>
   buf=""; i=0
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

# sets one cell to visually match what it is in the database
recover() { # <y> <x>
   buf="$(collide $1 $2)"
   if [ "$buf" ]; then
      fakedraw $1 $2 "$buf"
   else
      fakedraw $1 $2 " "
   fi
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

# return all instances of a character on screen
grepfind() { # <char>
   set | grep "^y[0-9]*x[0-9]*=[']*${1}[']*"
}

debug() { # <string>
   printf '[H%s' "$*"
}

# add characters in a box shape between 2 points
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

# outputs arguments for drawbox
# an alternate method of using drawbox that is usually easier
gensquare() { # <y> <x> <y radius> <x radius>
   # returns: "<y1> <x1> <y2> <x2>"
   echo "$(($1-$3)) $(($2-$4)) $(($1+$3)) $(($2+$4))"
}

# returns what is in a location in the database
collide() { # <y> <x>
   # returns: <char>
   eval "echo \"\$y${1}x${2}\""
}

# scan for a specific character in a direction
# stops at the first instance
hitscan() { # <y> <x> <direction> <character>
   # returns: "<y> <x>" OR null
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
# stops at the first cell that isn't null
hitscan_any() { # <y> <x> <direction>
   # returns: "<y> <x> <char>" OR null
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

prompt() {
   if [ "$1" ]; then
      ans="$1"
   else
      ans="REPLY"
   fi
   fakelineclear $((lines-1))
   fakedraw $((lines-1)) 1 ":"
   printf '[?25h'
   stty echo icanon
   read -r ${ans?}
   stty -echo -icanon
   printf '[?25l'
   fakelineclear $((lines-1))
   recover_all
}

# save the database to a file in the form of variable declarations
savedb() {
   [ "$1" ] || return 1
   echo "# generated by shell game engine" > "$1"
   set | grep '^y[0-9]*x[0-9]*' >> "$1"
}

# lets "." command more convenient
smart_source() {
   case "$1" in
      /*|./*|../*)
         buf="$1";;
      *)
         buf="./$1";;
   esac
   . $buf
}
