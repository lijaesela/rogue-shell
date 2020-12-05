# rogue-shell
a terminal-based game engine written entirely in POSIX shell.  
comes with example programs to showcase its capabilities.
### usage
the basic shell of a game looks something like this:
```shell
# source the engine
. ./base.sh
# clear the screen and set up size handling
term_init
# main loop
while true; do
   # pause for input and put it in variable 'input'
   getkey input
   # quit if q pressed
   if [ "$input" = "q" ]; then
      break
   fi
done
# return the terminal back to normal and exit
term_shutdown
```
### performance
this engine works best with minimal, POSIX-compliant shells.  
here is my ranking of the shells I've tried, from my experience:
```
dash
yash
bash
ksh
mksh
osh
```
