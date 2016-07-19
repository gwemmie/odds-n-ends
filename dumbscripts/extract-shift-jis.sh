#!/bin/bash
# Extract a SHIFT-JIS-encoded archive using 7z & convert its files
# Plagiarized from https://www.reddit.com/r/linuxquestions/comments/4tb8yr/linux_support_for_shiftjis/d5goxjw
# I could've made it myself, but someone else made it when I was trying
# to ask for a much better solution than this script.
# I did modify it a lot though.

ERROR="false"
if ! hash 7z 2>/dev/null; then
  echo "extract-shift-jis.sh: error: 7z is required"
  notify-send "extract-shift-jis.sh: error: 7z is required"
  ERROR="true"
fi
if ! hash convmv 2>/dev/null; then
  echo "extract-shift-jis.sh: error: convmv is required"
  notify-send "extract-shift-jis.sh: error: convmv is required"
  ERROR="true"
fi
if ! hash iconv 2>/dev/null; then
  echo "extract-shift-jis.sh: error: iconv is required"
  notify-send "extract-shift-jis.sh: error: iconv is required"
  ERROR="true"
fi
if [ "$ERROR" = "true" ]; then exit 1; fi

for ARCHIVE in "$@"; do
  if ! [ -f "$ARCHIVE" ]; then
    echo "extract-shift-jis.sh: error: archive file not found"
    notify-send "extract-shift-jis.sh: error: archive file not found"
    exit 1
  fi
  FOLDER="$(echo "$ARCHIVE" | perl -pe 's/\.[^.]+$//' | perl -pe 's/\.tar$//' | cut -d'/' -s -f1- --output-delimiter=$'\n' | tail -1)"
  mkdir -p "./$FOLDER"
  env LANG=C 7z x -o"./$FOLDER" "$ARCHIVE"
  convmv -f shift-jis -t utf8 --notest -r "./$FOLDER"
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in $(find "./$FOLDER" -type f -print); do
    if iconv -f shift-jis -t utf8 -o "$i.iconv" "$i"
    then mv "$i.iconv" "$i"
    # commented out because then you'd get logs for all non-text files
    #else iconv -f shift-jis -t utf8 -o "$i.iconv" "$i" 1>&2 2>"$i.iconv.log"
    fi
  done
  IFS=$SAVEIFS
done
