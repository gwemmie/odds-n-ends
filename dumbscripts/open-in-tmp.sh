#!/bin/bash
# Move video file(s) to /tmp, then open them.
# I made this because I keep freshly downloaded YouTube videos in a
# Downloads folder until I watch them, and moving them myself every time
# was getting cumbersome.
# New feature: backs up a list of your downloaded videos so that getting
# them back isn't a nightmare if your hard drive dies before you back it
# up.

PLAYER=/usr/bin/smplayer

for i in "$@"; do
  if [ -d "$i" ]; then
    echo "open-in-tmp.sh: error: directories not supported"
    notify-send "open-in-tmp.sh: error: directories not supported"
    exit 1
  fi
  if ! [ -f "$i" ]; then
    echo "open-in-tmp.sh: error: file not found"
    notify-send "open-in-tmp.sh: error: file not found"
    exit 1
  fi
  mv "$i" /tmp/
done

ls --group-directories-first $HOME/Downloads > $HOME/Dropbox/Settings/Scripts/Downloads

ARGS=()
for i in "$@"; do
  # get the last part of the path after the last slash, i.e. filename
  if [[ "$i" =~ '/' ]]
  then ARG="\"/tmp/$(echo $i | cut -d'/' -s -f1- --output-delimiter=$'\n' | tail -1)\""
  else ARG="\"/tmp/$i\""
  fi
  # skip subtitles files
  if [[ "$ARG" =~ ".srt" ]] || [[ "$ARG" =~ ".ass" ]] || [[ "$ARG" =~ ".ssa" ]] || [[ "$ARG" =~ ".sub" ]]
  then continue
  else ARGS+=( "$ARG" )
  fi
done

sleep 0.2
eval "$PLAYER" ${ARGS[@]} & disown
