#!/bin/bash
# monitor for quodlibet to quit and stop all the scripts in that event

notify-send "quodlibet script ready to exit"
rm $HOME/.dumbscripts/quodlibet-starting
while true; do
  if [ "$(pkill -0 -fc 'python2 /usr/bin/quodlibet --run')" = "0" ]; then
    killall quodlibet
    killall quodlibet-monitor.sh
    pkill -f "dbus-monitor --profile interface='net.sacredchao.QuodLibet',member='SongStarted'"
    notify-send "quodlibet has exited"
    exit
  fi
  sleep 2
done
