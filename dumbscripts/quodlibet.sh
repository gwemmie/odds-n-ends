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
elif pgrep 'quodlibet' | grep -v $$; then
  killall quodlibet-monitor.sh &
  pkill -f "dbus-monitor --profile interface='net.sacredchao.QuodLibet',member='SongStarted'"
  check-queue
  /home/jimi/.dumbscripts/quodlibet-monitor.sh &
  exit
fi

quodlibet --run --hide-window &
sleep 7
# I don't get it! This line works if I do it manually in bash, but NOT in the script
#while [[ "$(quodlibet --status)" =~ "not running" ]]; do sleep 1; done
load-queue-startup
/home/jimi/.dumbscripts/quodlibet-quit.sh &
/home/jimi/.dumbscripts/quodlibet-monitor.sh &

exit
