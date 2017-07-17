#!/bin/bash
# Swaps the current window between 2 monitors that are on the same "screen" without you having to drag it and perfectly align it
SCREENWIDTH=1920 # left monitor's X resolution
# xdotool moves certain windows by slightly too much for some reason???
ERRORX=0
ERRORY=0
WINDOW=$(xdotool getactivewindow)
WINDOWPOS=$(xdotool getwindowgeometry $WINDOW | grep Position | sed 's/\s*Position: \([0-9]\+\),\([0-9]\+\) .*/\1 \2/')
WINDOWX=$(echo $WINDOWPOS | awk '{print $1}')
WINDOWY=$(echo $WINDOWPOS | awk '{print $2}')
POS=""
if ! ([[ "$(xdotool getwindowname $WINDOW)" =~ "Firefox" ]] \
   || [[ "$(xdotool getwindowname $WINDOW)" =~ "Steam" ]]); then
  ERRORX=2
  ERRORY=56
fi
if [ $WINDOWX -ge $SCREENWIDTH ]
then POS=$(expr $WINDOWX - 1920 + 120) # 120 is my XFCE panel width
else POS=$(expr $WINDOWX + 1920 - 120)
fi
xdotool windowmove $WINDOW $(expr $POS - $ERRORX) $(expr $WINDOWY - $ERRORY)
# window might be maximized (if it didn't move, that's our proof):
if [ "$(xdotool getwindowgeometry $WINDOW | grep Position | sed 's/\s*Position: \([0-9]\+\),\([0-9]\+\) .*/\1 \2/')" = "$WINDOWPOS" ]; then
  xdotool keyup Control+Alt+s # shortcut used to run this script; interferes with Alt+F10
  xdotool key Alt+F10 # XFCE (un)maximize shortcut
  xdotool windowmove $WINDOW $(expr $POS - $ERRORX) $(expr $WINDOWY - $ERRORY)
  xdotool windowfocus $WINDOW
  xdotool key Alt+F10 # maximize it again when it's moved over
fi
exit

# OLD VERSION OF SCRIPT:
# For if you'd rather switch screens with a hotkey than be able to move
# your mouse between them. I hate that feature because I lose track of
# my mouse too easily.
SCREEN=$(xdotool getmouselocation | sed -r 's/.*screen:(.+) .*/\1/')

if [ "$SCREEN" = "0" ]; then
  xdotool mousemove --screen 1 100 100
elif [ "$SCREEN" = "1" ]; then
  xdotool mousemove --screen 0 100 100
else
  echo "Invalid screen"
  notify-send "Invalid screen"
fi
