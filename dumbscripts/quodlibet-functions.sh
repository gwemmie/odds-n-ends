#!/bin/bash

function load-queue-startup {
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  # to fix a bug mentioned in quodlibet-monitor.sh
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-first-queue
  quodlibet --unqueue= &
  wait $!
  echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $HOME/Dropbox/Playlists/queue)" > $HOME/.quodlibet/control &
  quodlibet --play-file="$(sed -n 1p $HOME/Dropbox/Playlists/queue)" &
  wait $!
  quodlibet --stop &
}

function load-queue {
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  quodlibet --unqueue= &
  wait $!
  echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $HOME/Dropbox/Playlists/queue)" > $HOME/.quodlibet/control &
  quodlibet --play-file="$(sed -n 1p $HOME/Dropbox/Playlists/queue)" &
}

function save-queue {
  echo -e "$(grep '~filename=' $HOME/.quodlibet/current | sed 's/~filename=//')\n$(python2 -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" "$(quodlibet --print-queue | sed 's|file://||g')")"
}

function check-queue {
  if diff $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue >/dev/null ; then
    # to avoid bug where print-queue returns nothing, resulting in just
    # the now-playing song being in the save-queue output
    while [ "$(save-queue | wc -l)" = "1" ]; do
      notify-send "might need to restart quodlibet"
      sleep 3
    done
    # & bug where it spits out whatever its queue was when it first ran
    while [ "$(save-queue)" = "$(cat $HOME/.dumbscripts/quodlibet-first-queue)" ]
    do sleep 1; done
    save-queue > $HOME/Dropbox/Playlists/queue
  else
    load-queue
  fi
}
