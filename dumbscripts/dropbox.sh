#!/bin/bash
# The script that does stuff whenever internet is lost and then regained
# Requires Dropbox to be always running; I will modify it otherwise if
# I stop using Dropbox

# Credit for the Dropbox part of this script goes to somebody on some
# forum somewhere. I forgot who it was. But, I've modified it so much
# that it's not really the same script anymore. Only the pipe into egrep
# is really theirs anymore.

INFO=$HOME/Dropbox/Settings/Scripts

while true; do
  if [ ! "$(pidof dropbox)" ]; then env -u QT_STYLE_OVERRIDE dropbox & fi
  dropbox-cli status | egrep 'isn|Connecting' >/dev/null
  if [ "$?" = 0 ]; then
    if nc -zw1 dropbox.com 80; then
      # restart Dropbox
      dropbox-cli stop
      sleep 2
      dropbox-cli start
      # restart Franz
      if [ "$(pidof franz)" ]; then killall franz ; sleep 2 ; /usr/bin/franz & fi
      $HOME/.dumbscripts/publish-ip.sh &
    fi
  fi
  sleep 5
done
