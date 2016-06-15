#!/bin/bash
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
