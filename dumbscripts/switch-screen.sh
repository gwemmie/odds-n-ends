#!/bin/bash
# Swaps the current window between 2 monitors that are on the same "screen" without you having to drag it and perfectly align it
SCREENWIDTH=1920 # left monitor's X resolution
# xdotool moves certain windows by slightly too much for some reason???
ERRORX=0
ERRORY=0
WINDOW=$(xdt getactivewindow)
WINDOWPOS=$(xdt getwindowgeometry $WINDOW | grep Position | sed 's/\s*Position: \([0-9]\+\),\([0-9]\+\) .*/\1 \2/')
WINDOWX=$(echo $WINDOWPOS | awk '{print $1}')
WINDOWY=$(echo $WINDOWPOS | awk '{print $2}')
POS=""
# Firefox also started needing ERRORX in v60 either because I was using nouveau, because of not using gtk3-mushrooms, or until v61 (all 3 of those system changes happened at the same time)
if ! [[ "$(xdt getwindowname $WINDOW)" =~ "Steam" ]] \
&& ! [[ "$(xdt getwindowname $WINDOW)" =~ "Firefox" ]]
then ERRORX=2
#elif [[ "$(xdt getwindowname $WINDOW)" =~ "Firefox" ]]
#then ERRORX=23
fi
# Firefox stopped needing ERRORY in version 57
# and started needing it again when I got to hide the titlebar in v60 either because I was using nouveau, because of not using gtk3-mushrooms (but still with GTK_CSD=0 so I can hide the titlebar), or until v61
if ! [[ "$(xdt getwindowname $WINDOW)" =~ "Steam" ]] \
&& ! [[ "$(xdt getwindowname $WINDOW)" =~ "Firefox" ]]
then ERRORY=56
#elif [[ "$(xdt getwindowname $WINDOW)" =~ "Firefox" ]]
#then ERRORY=14
fi
if [ $WINDOWX -ge $SCREENWIDTH ]
then POS=$(expr $WINDOWX - 1920 + 120) # 120 is my XFCE panel width
else POS=$(expr $WINDOWX + 1920 - 120)
fi
xdt windowmove $WINDOW $(expr $POS - $ERRORX) $(expr $WINDOWY - $ERRORY)
# window might be maximized (if it didn't move, that's our proof):
if [ "$(xdt getwindowgeometry $WINDOW | grep Position | sed 's/\s*Position: \([0-9]\+\),\([0-9]\+\) .*/\1 \2/')" = "$WINDOWPOS" ]; then
  xdt keyup Control+Alt+s # shortcut used to run this script; interferes with Alt+F10
  xdt windowfocus $WINDOW
  xdt key Alt+F10 # XFCE (un)maximize shortcut
  sleep 0.2
  xdt windowmove $WINDOW $(expr $POS - $ERRORX) $(expr $WINDOWY - $ERRORY)
  xdt windowfocus $WINDOW
  xdt key Alt+F10 # maximize it again when it's moved over
fi
exit

# OLD VERSION OF SCRIPT:
# For if you'd rather switch screens with a hotkey than be able to move
# your mouse between them. I hate that feature because I lose track of
# my mouse too easily.
SCREEN=$(xdt getmouselocation | sed -r 's/.*screen:(.+) .*/\1/')

if [ "$SCREEN" = "0" ]; then
  xdt mousemove --screen 1 100 100
elif [ "$SCREEN" = "1" ]; then
  xdt mousemove --screen 0 100 100
else
  echo "Invalid screen"
  notify-send "Invalid screen"
fi
