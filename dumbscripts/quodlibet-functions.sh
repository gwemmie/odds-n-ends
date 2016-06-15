#!/bin/bash

function load-queue-startup {
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  quodlibet --unqueue= &
  sleep 2
  echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $HOME/Dropbox/Playlists/queue)" > $HOME/.quodlibet/control &
  quodlibet --play-file="$(sed -n 1p $HOME/Dropbox/Playlists/queue)" &
  sleep 0.28
  quodlibet --stop &
}

function load-queue {
  chmod -w $HOME/Dropbox/Playlists/queue
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
  quodlibet --unqueue= &
  sleep 2
  echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $HOME/Dropbox/Playlists/queue)" > $HOME/.quodlibet/control &
  quodlibet --play-file="$(sed -n 1p $HOME/Dropbox/Playlists/queue)" &
  sleep 2
  chmod 644 $HOME/Dropbox/Playlists/queue
}

function save-queue {
  echo -e "$(grep '~filename=' $HOME/.quodlibet/current | sed 's/~filename=//')\n$(python2 -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" "$(quodlibet --print-queue | sed 's|file://||g')")" > $HOME/Dropbox/Playlists/queue
  sleep 1
  cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
}

function check-queue {
  if diff $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue >/dev/null ; then
    save-queue
  else
    load-queue
  fi
}
