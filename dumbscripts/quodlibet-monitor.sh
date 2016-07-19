#!/bin/bash
source $HOME/.dumbscripts/quodlibet-functions.sh
FIRST_QUEUE="$(save-queue)"

# monitor for song changes & save queue
dbus-monitor --profile "interface='net.sacredchao.QuodLibet',member='SongStarted'" |
while read -r line; do
  # this keeps getting reset somehow
  sed -i 's/^ascii = true$/ascii = false/' $HOME/.quodlibet/config
  # avoid saving an empty queue
  # & avoid bug where print-queue returns nothing, resulting in just
  # the now-playing song being in the save-queue output
  # & skip if this particular queue has already been saved
  # & avoid bug where dbus-monitor tries to save the first queue several
  # times when it first starts running
  if [ "$(save-queue)" = ""] \
  || [ "$(save-queue | wc -l)" = "1" ] \
  || [ "$(save-queue)" = "$(<$QUEUE_FILE)" ] \
  || [ "$(save-queue)" = "$FIRST_QUEUE" ]; then
    continue
  else
    # prefer sponge from moreutils: less buggy writing a lot at once
    if hash sponge 2>/dev/null; then
      save-queue | sponge $QUEUE_FILE
    else
      save-queue > $QUEUE_FILE
    fi
    sleep 1
    cp $QUEUE_FILE $QUEUE_LOCAL
  fi
done
