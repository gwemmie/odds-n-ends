#!/bin/bash
source $HOME/.dumbscripts/quodlibet-functions.sh
NEWER_QUEUE="$(save-queue)"

# monitor for song changes & save queue
dbus-monitor --profile "interface='net.sacredchao.QuodLibet',member='SongStarted'" |
while read -r line; do
  # to avoid bug where print-queue returns nothing, resulting in just
  # the now-playing song being in the save-queue output
  while [ "$(save-queue | wc -l)" = "1" ]; do
    notify-send "might need to restart quodlibet"
    sleep 3
  done
  # & bug where it spits out whatever its queue was when it first ran
  while [ "$(save-queue)" = "$(cat $HOME/.dumbscripts/quodlibet-first-queue)" ]
  do sleep 1; done
  # & bug where dbus-monitor tries to save the first queue several times
  # when it first starts running
  if [ "$(save-queue)" = "$NEWER_QUEUE" ]; then continue; fi
  # & bug where dbus-monitor tries to save the queue several times
  if [ "$(save-queue)" = "$(cat $HOME/Dropbox/Playlists/queue)" ]; then continue; fi
  save-queue > $HOME/Dropbox/Playlists/queue
  sleep 1
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
done
