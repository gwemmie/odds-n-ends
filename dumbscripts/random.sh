#!/bin/bash
# Use viewnoir to run a random slideshow of images in the given
# directory ($1), each image being open for a given amount of time
# ($2 seconds).

# Once it gets going, it will never stop until you delete the random
# file. My playpause.sh script does that. I like to bind that script to
# my play/pause button on my keyboard.

# Uses exiftool to automatically play out an entire gif's animation
# instead of closing in $2 seconds.

# This script replaces a feature that I missed after switching from KDE,
# because every Linux image viewer that isnt Gwneview is inexplicably
# missing tons of extremely basic and common features.

FOLDERS=()
COUNTER=0

echo "random" > $HOME/.dumbscripts/random
cd "$1"
if [ "$3" = "--recursive" ]; then
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in $(ls -1d */)
  do FOLDERS+=( "$i" )
  done
  IFS=$SAVEIFS
fi
TIME="$2"
while [ -f $HOME/.dumbscripts/random ]; do
  if [ "$3" = "--recursive" ]; then
    cd "${FOLDERS[$COUNTER]}"
    let COUNTER+=1
    if [ "$COUNTER" = "${#FOLDERS[@]}" ]
    then COUNTER=0
    fi
  fi
  LINES=$(ls -1 "$1" | wc -l)
  RAND=$(expr $RANDOM + 1)
  LINE=$(expr $RAND % $LINES)
  FILE=$(ls -1 . | sort -R | sed -n "$LINE p")
  if [[ "$FILE" =~ ".gif" ]]; then TIMEOUT=$(echo "$(exiftool -Duration "$FILE" | sed 's/Duration\W*: \([0-9].*\) s/\1/g') * 2 + 0.2" | bc)
  else TIMEOUT=$TIME ; fi
  timeout "$TIMEOUT"s viewnior --fullscreen "$FILE"
  if [ "$3" = "--recursive" ]
  then cd ..
  fi
done
