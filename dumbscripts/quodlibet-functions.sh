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
    # skip the whole thing if this particular queue has already been saved
    # & avoid saving an empty queue
    # & avoid bug where print-queue returns nothing, resulting in just
    # the now-playing song being in the save-queue output
    # & bug where it spits out whatever its queue was when it first ran
    if [ "$(save-queue)" = ""] \
    || [ "$(save-queue | wc -l)" = "1" ] \
    || [ "$(save-queue)" = "$(cat $HOME/.dumbscripts/quodlibet-first-queue)" ] \
    || [ "$(save-queue)" = "$(cat $HOME/Dropbox/Playlists/queue)" ]; then
      #notify-send "quodlibet queue did not save"
      return
    else
      notify-send "quodlibet queue saved"
      save-queue > $HOME/Dropbox/Playlists/queue
      sleep 1
      cp $HOME/Dropbox/Playlists/queue $HOME/.dumbscripts/quodlibet-local-queue
    fi
  else
    load-queue
  fi
}
