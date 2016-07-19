#!/bin/bash
QUEUE_FILE=$HOME/Dropbox/Settings/Scripts/quodlibet-queue
QUEUE_LOCAL=$HOME/.dumbscripts/quodlibet-local-queue

function load-queue {
  cp $QUEUE_FILE $QUEUE_LOCAL
  quodlibet --unqueue= &
  wait $!
  echo -e "enqueue $(sed '1d;:a;N;$!ba;s|\n|\nenqueue |g' $QUEUE_FILE)" > $HOME/.quodlibet/control &
  quodlibet --play-file="$(sed -n 1p $QUEUE_FILE)" &
  wait $!
}

function save-queue {
  # Had to break out xargs to support arbitrarily large queues.
  # Also had to use that dumb -I{} option because otherwise python would
  # ignore about 99% of the lines that --print-queue outputted.
  # No, I don't know why.
  # Also had to use -P 6 to make xargs not run ungodly slowly. Change
  # the number if your system isn't as powerful.
  echo -e "$(grep '~filename=' $HOME/.quodlibet/current | sed 's/~filename=//')\n$(quodlibet --print-queue | xargs -I{} -d '\n' python2 -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" "{}" | sed 's|file://||g')"
}

function check-queue {
  if diff $QUEUE_FILE $QUEUE_LOCAL >/dev/null ; then
    # avoid saving an empty queue
    # & avoid bug where print-queue returns nothing, resulting in just
    # the now-playing song being in the save-queue output
    # & skip if this particular queue has already been saved
    if [ "$(save-queue)" = ""] \
    || [ "$(save-queue | wc -l)" = "1" ] \
    || [ "$(save-queue)" = "$(<$QUEUE_FILE)" ]; then
      return
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
  else
    load-queue
  fi
}
