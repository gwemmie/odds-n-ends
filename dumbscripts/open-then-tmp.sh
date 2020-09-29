#!/bin/bash
# Automatically move video file(s) to /tmp after viewing them.
# (when the process that's viewing them closes)
# I made this because I keep freshly downloaded YouTube videos in a
# videos folder until I watch them, and moving them myself every time
# was getting cumbersome.

PLAYER=smplayer
FOLDER=/tmp/vids

$HOME/.dumbscripts/update-downloads.sh # organize downloads & export a list of them

for i in "$@"; do
  if [ -d "$i" ]; then
    echo "$(basename $0): error: directories not supported"
    notify-send "$(basename $0): error: directories not supported"
    exit 1
  fi
  if ! [ -f "$i" ]; then
    echo "$(basename $0): error: file not found"
    notify-send "$(basename $0): error: file not found"
    exit 1
  fi
done

if ! [ -d "$FOLDER" ]
then mkdir -p "$FOLDER"
fi

ARGS=()
FILES=()
for i in "$@"; do
  # skip subtitles files
  if [[ "$i" =~ ".srt" ]] || [[ "$i" =~ ".ass" ]] || [[ "$i" =~ ".ssa" ]] || [[ "$i" =~ ".sub" ]] || [[ "$i" =~ ".idx" ]] || [[ "$i" =~ ".vtt" ]]
  then continue
  fi
  ARG="$(cd "$(dirname "$i")"; pwd -P)/$(basename "$i")" # get full path
  ARGS+=( "$ARG " )
  # make temporary file to show watching status
  FILE="$FOLDER/~watching - $(basename "$i" | sed 's/.part$//')"
  echo "$i" > "$FILE"
  FILES+=( "$FILE" )
done

$PLAYER "${ARGS[@]}" &
wait $!
disown

for i in "${FILES[@]}"
do rm "$i"
done
for i in "$@"
do mv "$(echo "$i" | sed 's/.part$//')" "$FOLDER/"
done
