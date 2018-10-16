#!/bin/bash
# Wrapper for youtube-dl to download videos in a queue instead of all at
# once
# Order is FIFO; each line of $PIDFILE is a PID
ERROR=0
PIDFILE=/tmp/queue-dl
GITS=$HOME/.local/share/git # where you store your custom git repos

# Plagiarized from http://stackoverflow.com/questions/1058047/wait-for-any-process-to-finish
function anywait {
  for PID in "$@"; do
    while ps -p "$PID" > /dev/null
    do sleep 0.5
    done
  done
}

if [ -f "$PIDFILE" ] && [ "$(sed -n 1p "$PIDFILE")" != "" ]; then
  echo $$ >> "$PIDFILE"
  set +e # somehow, this is required, even though I never set -e earlier
  # I like to type `queue-dl "nothing"; something` if I want something to happen after a download, like shutting down my computer, so this gets rid of the youtube-dl spam
  if [ "$1" != "nothing" ]
  then echo "Downloading $(youtube-dl --get-title "$@")..."
  fi
  if [ "$(sed -n 1p "$PIDFILE")" != "$$" ]; then
    echo "PID: $$"
    echo "Downloads ahead in line (by PID) are: $(sed "/$$/d" "$PIDFILE" | perl -0777 -pe 's/\n/,/g' | sed 's/,$//')"
    while [ "$(sed -n 1p "$PIDFILE")" != "$$" ]; do
      PID=$(sed -n 1p "$PIDFILE")
      if ! ps -p "$PID" > /dev/null
      then
        echo "$PID turned out to not be running"
        sed -i "/$PID/d" "$PIDFILE"
      else
        echo "Waiting for $PID"
        anywait $(sed -n 1p "$PIDFILE")
      fi
    done
  fi
else echo $$ > "$PIDFILE"
fi
if [ "$1" != "nothing" ]; then
  if [ "$i" = "--branch" ]
  then $GITS/youtube-dl-$2 "${@:3}"
  else youtube-dl "$@"
  fi
  ERROR=$?
fi
sed -i "/^$$\$/d" "$PIDFILE"
if [ "$(<"$PIDFILE")" = "" ]
then rm "$PIDFILE"
fi

exit $ERROR
