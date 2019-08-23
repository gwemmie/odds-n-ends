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
PODCAST="/tmp/podcast-playing"
WINDOW="$(xdt getwindowname $(xdt getactivewindow))"

set -x

if [ "$1" != "pause-all" ]; then

if [ -f "$PODCAST" ]
then $HOME/.dumbscripts/podcast.sh pause
elif [ -f $HOME/.dumbscripts/random ]; then
  rm $HOME/.dumbscripts/random
else
  if [[ "$WINDOW" =~ "SMPlayer" ]] || [[ "$WINDOW" =~ "plugin-container" ]] \
  || [[ "$WINDOW" =~ "VLC media player" ]]; then
    sleep 0.1
    if [[ "$WINDOW" =~ "plugin-container" ]]
    then xdt key space
    elif [[ "$WINDOW" =~ "SMPlayer" ]]
    then qdbus org.mpris.MediaPlayer2.smplayer /org/mpris/MediaPlayer2 PlayPause
    elif [[ "$WINDOW" =~ "VLC media player" ]]
    then qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    fi
  elif pacmd list sinks | grep -q 'device.description = "HD 4.40BT"\|device.description = "MM100"\|device.description = "LBT-PAR500'
  then
    if [ "$1" != "check" ]  && [[ "$WINDOW" =~ "Roll20" ]]; then # | [[ "$WINDOW" =~ "Discord" ]]
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
      quodlibet --play-pause & disown
    fi
  elif [ "$1" != "check" ]; then
    #pkill -f 'python2 /home/jimi/.clementine-webremote/clementineWebRemote.py'
    sleep 0.1
    quodlibet --play-pause & disown
  fi
fi

else # pause everything

sleep 0.1
$HOME/.dumbscripts/podcast.sh pause
if [[ "$WINDOW" =~ "plugin-container" ]]
then xdt key space
fi
qdbus org.mpris.MediaPlayer2.smplayer /org/mpris/MediaPlayer2 Pause
qdbus org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause
quodlibet --pause & disown

fi
