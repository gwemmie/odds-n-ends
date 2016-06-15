#!/bin/bash
source $HOME/.dumbscripts/quodlibet-functions.sh

# monitor for song changes & save queue
dbus-monitor --profile "interface='net.sacredchao.QuodLibet',member='SongStarted'" |
while read -r line; do
  save-queue
done
