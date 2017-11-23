#!/bin/bash
QUEUE_FILE=$HOME/Dropbox/Settings/Scripts/quodlibet-queue
QUEUE_LOCAL=$HOME/.dumbscripts/quodlibet-local-queue

function load-queue {
  # avoid Dropbox bug where queue file goes empty or one line
  if [ "$(<$QUEUE_FILE)" = "" ] || [ "$(<$QUEUE_FILE | wc -l)" = "1" ]; then
    notify-send "quodlibet sync file is empty"
    cp $QUEUE_LOCAL $QUEUE_FILE
  else
    cp $QUEUE_FILE $QUEUE_LOCAL
    quodlibet --unqueue= &
    wait $!
    echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $QUEUE_LOCAL)" > $HOME/.quodlibet/control &
    quodlibet --play-file="$(sed -n 1p $QUEUE_LOCAL)" &
    wait $!
  fi
}

function save-queue {
  # Had to break out xargs to support arbitrarily large queues.
  echo -e "$(grep '~filename=' $HOME/.quodlibet/current | sed 's/~filename=//')\n$(quodlibet --print-queue | xargs -I{} -d '\n' python2 -c "import sys, urllib as ul; print ul.unquote(sys.argv[1])" "{}" | sed 's|file://||g')"
}

function check-queue {
  if diff $QUEUE_LOCAL $QUEUE_FILE >/dev/null ; then
    # avoid saving an empty queue
    # & avoid bug where print-queue returns nothing, resulting in just
    # the now-playing song being in the save-queue output
    # & skip if this particular queue has already been saved
    if [ "$(save-queue)" = ""] \
    || [ "$(save-queue | wc -l)" = "1" ] \
    || [ "$(save-queue)" = "$(<$QUEUE_LOCAL)" ]; then
      return
    else
      # prefer sponge from moreutils: less buggy writing a lot at once
      if hash sponge 2>/dev/null
      then save-queue | sponge $QUEUE_LOCAL
      else save-queue > $QUEUE_LOCAL
      fi
      sleep 1
      cp $QUEUE_LOCAL $QUEUE_FILE
    fi
  else
    load-queue
  fi
}
