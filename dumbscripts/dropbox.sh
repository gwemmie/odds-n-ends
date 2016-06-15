#!/bin/bash
# Credit for this script goes to somebody on some forum somewhere. I
# forgot who it was. But, I've modified it so much that it's not really
# the same script anymore. Only the pipe into egrep is really theirs
# anymore.

while true; do
  if [ ! "$(pidof dropbox)" ]; then env -u QT_STYLE_OVERRIDE dropbox & fi
  dropbox-cli status | egrep 'isn|Connecting' >/dev/null
  if [ "$?" = 0 ]; then
    if nc -zw1 dropbox.com 80; then
      dropbox-cli stop
      sleep 2
      dropbox-cli start
    fi
  fi
  sleep 5
done
