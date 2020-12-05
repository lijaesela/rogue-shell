#!/bin/sh -ef
#shellcheck disable=SC2086
#shellcheck disable=SC2046

#
# level editor, works like a paint program
# 'hjkl' moves the cursor
# 'HJKL' moves and paints what you last inserted (useful!!!)
# 'i' inserts one character
# 'd' deletes one character
# 'w' saves the file
# 'q' quits
# any key not reserved here is simply inserted if pressed.
#

. ./core.sh
term_init

# read/create file
if [ "$1" ]; then
   file="$1"
   if [ -f "$file" ]; then
      smart_source "$file"
      recover_all
   fi
else
   file="paintdbfile"
fi

# main
brush_y=$((lines/2))
brush_x=$((columns/2))
while true; do
   under="$(collide $brush_y $brush_x)"
   if [ "$under" ]; then
      brush="$under"
   else
      brush="~"
   fi
   fakedraw $brush_y $brush_x "[31;1m$brush[m"
   getkey key
   recover $brush_y $brush_x
   case $key in
      k) brush_y=$((brush_y-1));;
      j) brush_y=$((brush_y+1));;
      h) brush_x=$((brush_x-1));;
      l) brush_x=$((brush_x+1));;
      K) brush_y=$((brush_y-1))
         drawchar $brush_y $brush_x "$lastkey";;
      J) brush_y=$((brush_y+1))
         drawchar $brush_y $brush_x "$lastkey";;
      H) brush_x=$((brush_x-1))
         drawchar $brush_y $brush_x "$lastkey";;
      L) brush_x=$((brush_x+1))
         drawchar $brush_y $brush_x "$lastkey";;
      d) nullify $brush_y $brush_x;;
      w) savedb $file;;
      q) term_shutdown;;
      i) fakedraw $brush_y $brush_x "!"
         getkey key
         drawchar $brush_y $brush_x "$key"
         lastkey="$key";;
      *) drawchar $brush_y $brush_x "$key"
         lastkey="$key";;
   esac
done
