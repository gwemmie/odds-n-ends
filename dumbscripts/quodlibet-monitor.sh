#!/bin/bash
source $HOME/.dumbscripts/quodlibet-functions.sh
NEWER_QUEUE="$(save-queue)"

# monitor for song changes & save queue
dbus-monitor --profile "interface='net.sacredchao.QuodLibet',member='SongStarted'" |
while read -r line; do
  # this keeps getting reset somehow
  sed -i 's/ascii = true/ascii = false/' $HOME/.quodlibet/config
  # skip the whole thing if this particular queue has already been saved
  # & avoid saving an empty queue
  # & avoid bug where print-queue returns nothing, resulting in just
  # the now-playing song being in the save-queue output
  # & bug where it spits out whatever its queue was when it first ran
  # & bug where dbus-monitor tries to save the first queue several times
  # when it first starts running
  # & bug where dbus-monitor tries to save the queue several times
  if [ "$NEWER_QUEUE" = "$(cat $HOME/.dumbscripts/quodlibet-first-queue)" ] \
  || [ "$(save-queue)" = ""] \
  || [ "$(save-queue | wc -l)" = "1" ] \
  || [ "$(save-queue)" = "$(cat $HOME/.dumbscripts/quodlibet-first-queue)" ] \
  || [ "$(save-queue)" = "$NEWER_QUEUE" ] \
  || [ "$(save-queue)" = "$(cat $HOME/Dropbox/Playlists/queue)" ]; then
    #notify-send "quodlibet queue did not save"
    continue
  else
    notify-send "quodlibet queue saved"
    save-queue > $HOME/Dropbox/Playlists/queue
    sleep 1
    cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  fi
done
