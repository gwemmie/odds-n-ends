#!/bin/bash
# Automatically move video file(s) to /tmp after viewing them.
# (when the process that's viewing them closes)
# I made this because I keep freshly downloaded YouTube videos in a
# Downloads folder until I watch them, and moving them myself every time
# was getting cumbersome.

PLAYER=/usr/bin/smplayer
FOLDER=/tmp/vids

$HOME/.dumbscripts/update-downloads.sh # organize downloads & export a list of them

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
done

if ! [ -d "$FOLDER" ]
then mkdir -p "$FOLDER"
fi

ARGS=()
FILES=()
for i in "$@"; do
  ARG="\"$i\""
  # skip subtitles files
  if [[ "$ARG" =~ ".srt" ]] || [[ "$ARG" =~ ".ass" ]] || [[ "$ARG" =~ ".ssa" ]] || [[ "$ARG" =~ ".sub" ]]
  then continue
  else ARGS+=( "$ARG" )
  fi
  # make temporary file to show watching status
  FILE="$FOLDER/~watching - $(basename "$i")"
  echo "$i" > "$FILE"
  FILES+=( "$FILE" )
done

eval "$PLAYER" ${ARGS[@]} &
wait $!
disown

for i in "${FILES[@]}"
do rm "$i"
done
for i in "$@"
do mv "$i" "$FOLDER/"
done
