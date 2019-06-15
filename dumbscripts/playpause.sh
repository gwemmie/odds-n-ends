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

function quodlibet-pause() {
  if [ "$1" = "check" ]
  then if ! quodlibet --status | grep -q playing
    then return
    fi
  fi
  quodlibet --play-pause & disown
}

set -x

WINDOW="$(xdt getwindowname $(xdt getactivewindow))"
if [ -f $HOME/.dumbscripts/random ]; then
  rm $HOME/.dumbscripts/random
else
  if pacmd list sinks | grep -q 'device.description = "HD 4.40BT"\|device.description = "MM100"\|device.description = "LBT-PAR500'
  then
    if [[ "$WINDOW" =~ "plugin-container" ]] || [[ "$WINDOW" =~ "VLC media player" ]] || [[ "$WINDOW" =~ "SMPlayer" ]]; then
      sleep 0.1
      xdt key space
    elif [[ "$WINDOW" =~ "Roll20" ]]; then # | [[ "$WINDOW" =~ "Discord" ]]
      if [[ "$WINDOW" =~ "Roll20" ]]; then
        xdt mousemove 1900 1000
        xdt mousedown 1
        xdt mouseup 1
      fi
      xdt key 'i' 'm' "space" 'a' 'f' 'k' KP_Enter
#    elif [ "$(pkill -0 -fc 'python2 /home/jimi/.clementine-webremote/clementineWebRemote.py')" = "0" ]; then
#      python2 /home/jimi/.clementine-webremote/clementineWebRemote.py
    else
      while [ -f "$HOME/.dumbscripts/quodlibet-starting" ]
      do sleep 1
      done
      quodlibet-pause $1
    fi
  else
    #pkill -f 'python2 /home/jimi/.clementine-webremote/clementineWebRemote.py'
    sleep 0.1
    quodlibet-pause $1
  fi
fi
