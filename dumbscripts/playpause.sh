#!/bin/bash
# Customize what the play/pause button on your keyboard can do.
# This script supports pausing full-screen flash/HTML5 video, VLC,
# SMPlayer, quodlibet, and works with my random.sh script to make it
# stop. It also types "im afk" into Roll20 if you are using a Sennheiser
# MM100 Bluetooth headset to hear your friends wonder where you are
# while you're AFK. That's extremely specific.
# It also has, commented out, what lengths I had to go through to make
# it support Clementine's web remote feature (another music player).
# Sorry, this script doesn't keep lines under 80 chars long.

set -x

WINDOW="$(xdotool getwindowname $(xdotool getactivewindow))"
if [[ "$WINDOW" =~ "plugin-container" ]] || [[ "$WINDOW" =~ "VLC media player" ]] || [[ "$WINDOW" =~ "SMPlayer" ]]; then
  sleep 0.1
  xdotool key space
elif [ -f $HOME/.dumbscripts/random ]; then
  rm $HOME/.dumbscripts/random
else
  if pacmd list sinks | grep -Fq 'HD 4.40BT\|MM100\|LBT-PAR500'
  then
    if [[ "$WINDOW" =~ "Roll20" ]] | [[ "$WINDOW" =~ "Discord" ]]; then
      if [[ "$WINDOW" =~ "Roll20" ]]; then
        xdotool mousemove 1900 1000
        xdotool mousedown 1
        xdotool mouseup 1
      fi
      xdotool key 'i' 'm' "space" 'a' 'f' 'k' KP_Enter
#    elif [ "$(pkill -0 -fc 'python2 /home/jimi/.clementine-webremote/clementineWebRemote.py')" = "0" ]; then
#      python2 /home/jimi/.clementine-webremote/clementineWebRemote.py
    else
      while [ -f "$HOME/.dumbscripts/quodlibet-starting" ]
      do sleep 1
      done
      quodlibet --play-pause & disown
    fi
  else
    #pkill -f 'python2 /home/jimi/.clementine-webremote/clementineWebRemote.py'
    sleep 0.1
    quodlibet --play-pause & disown
  fi
fi
