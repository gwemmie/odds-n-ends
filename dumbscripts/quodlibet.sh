#!/bin/bash
# A huge wrapper for quodlibet that does various things.

# This nexus of quodlibet scripts makes its queue actually robust and
# sync to DropBox. Without this script, quodlibet's default queue
# behavior is atrocious. It will forget files, not always remember what
# it was playing on shutdown, and ALWAYS add the now-playing song to the
# end of the queue on shutdown for some reason. It was impossible to use
# the queue without constant babysitting.

# Running in the background, these scripts turn quodlibet into a daemon,
# and automatically save the queue to DropBox every time a new song
# starts playing, and also if you launch the script again while it's
# already running.

# Another feature it has that probably only I will care about is: it
# makes sure only one of your multiple networked computers (in these
# scripts, it's named ROUTER, and is stored by hostname in the file
# $HOME/Dropbox/Settings/Scripts/ROUTER) runs quodlibet. That way, you
# can have quodlibet automatically run at boot on your desktop, and
# then have it run at boot on your laptop if you're away from home with
# just your laptop, all automatically. To use that feature, run the
# quodlibet-wait.sh script to run quodlibet INSTEAD of this main one.

source $HOME/.dumbscripts/quodlibet-functions.sh
killall quodlibet-wait.sh & rm $HOME/.dumbscripts/quodlibet-found-router

if [ ! $# -eq 0 ]; then
  quodlibet --run --play-file "$@" &
  exit
elif [ "$(pkill -0 -fc 'python2 /usr/bin/quodlibet')" = "1" ]; then
  killall quodlibet-monitor.sh &
  pkill -f "dbus-monitor --profile interface='net.sacredchao.QuodLibet',member='SongStarted'"
  check-queue
  sleep 5
  # The following witchery is taking place because dbus-monitor will,
  # as soon as it's run, immediately puke out a random amount of lines
  # that we do NOT want to act on (because they're garbage). By the time
  # we're 10 seconds in, it will be done with that garbage. You may get
  # error messages from quodlibet complaining that it couldn't modify
  # the read-only file. Ignore them. This is the only way I could manage
  # to bypass that initial garbage, but still save the queue as soon as
  # the first song finishes playing.
  chmod -w $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  /home/jimi/.dumbscripts/quodlibet-monitor.sh &
  sleep 10
  chmod 644 $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  exit
fi

quodlibet --run --hide-window &
sleep 7
load-queue-startup

sleep 5

/home/jimi/.dumbscripts/quodlibet-quit.sh &
chmod -w $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
/home/jimi/.dumbscripts/quodlibet-monitor.sh &
sleep 10
chmod 644 $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue

exit
