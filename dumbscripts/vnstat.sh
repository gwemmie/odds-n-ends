#!/bin/bash
# Keeps track of how much bandwidth you used while vnstat was "paused"
# I made this because vnstat --enable/--disable were too unreliable
# It's set to go month-by-month, resetting on day 1 of a month. You can
# change that by modifying or deleting the first if block.

if [ $# -eq 0 ] || [ "$1" = "pause" ] || [ "$1" = "resume" ]; then
  INTERFACE=$(ip route ls | grep 'default via' | head -1 | awk '{ print $5}')
  TRACKER="$HOME/.dumbscripts/vnstat" # the file that keeps track
else
  /usr/bin/vnstat $@
  exit
fi

# gets the adjusted value of vnstat's current count
function adjusted-value {
  OLD="$(/usr/bin/vnstat | grep $(date +%b) | grep -v 'Database updated' | sed 's/.*|.*|\s\+\([0-9]*\.*[0-9]*\s\+[A-Za-z]iB\)\s\+|.*/\1/')"
  DIF="$(sed -n 1p "$TRACKER")"
  OLDNUM="$(echo $OLD | sed 's/\s\+[A-Za-z]iB//')"
  DIFNUM="$(echo $DIF | sed 's/\s\+[A-Za-z]iB//')"
  BYTE=""
  if [ "$OLDNUM" = "0" ] || [ "$OLDNUM" = "0.0" ]
  then BYTE="$(echo $DIF | sed 's/[0-9]*\.*[0-9]*\s\+//')"
  else
    BYTE="$(echo $OLD | sed 's/[0-9]*\.*[0-9]*\s\+//')"
    if [ "$BYTE" != "$(echo $DIF | sed 's/[0-9]*\.*[0-9]*\s\+//')" ] \
    && [ "$DIFNUM" != "0" ] && [ "$DIFNUM" != "0.0" ]; then
      echo "vnstat error: byte type mismatch: subtract $DIF from $OLD"
      return
    fi
  fi
  echo "$(echo "$OLDNUM-$DIFNUM" | bc -l) $BYTE"
}

# clear file if it's a new month
if ! [ -f "$TRACKER" ] \
|| [ "$(stat -c %y $TRACKER | sed "s/$(date +%Y)-\([0-9][0-9]\)-.*/\1/")" != "$(date +%m)" ]
then
  echo "0 GiB" > "$TRACKER"
  echo "$INTERFACE" >> "$TRACKER"
fi

# check interface match
if [ "$(sed -n 2p "$TRACKER")" != "$INTERFACE" ]; then
  echo -n "WARNING: interface mismatch: "
  echo "this count is on $(sed -n 2p "$TRACKER") but you are using $INTERFACE"
  read -p "Clear count and replace with new interface? [Y/N] " ANS
    case $ANS in
      [yY]* ) echo "0 GiB" > "$TRACKER"
        echo "$INTERFACE" >> "$TRACKER"
        break;;
      [nN]* ) exit;;
    esac
fi

# pause, resume, or show vnstat with adjusted value
if [ "$1" = "pause" ]; then
  if grep -Fq "paused at" "$TRACKER"; then
    echo "vnstat already $(sed -n 3p "$TRACKER")"
    exit
  fi
  echo "Updating database..."
  echo # for some reason, this is necessary to get a line break
  sudo vnstat -u
  PAUSE="$(adjusted-value)"
  if [[ "$PAUSE" =~ "error" ]]; then
    echo "paused at something" >> "$TRACKER"
    echo "$PAUSE"
    echo "and replace \"something\" with the result in $TRACKER"
  else
    echo -n "vnstat "
    echo "paused at $PAUSE" | tee -a "$TRACKER"
  fi
elif [ "$1" = "resume" ]; then
  if ! grep -Fq "paused at" "$TRACKER"; then
    echo "vnstat already resumed"
    exit
  fi
  echo "Updating database..."
  sudo vnstat -u
  OLD="$(sed -n 1p "$TRACKER")"
  DIF1="$(sed -n 3p "$TRACKER" | sed 's/paused at //')"
  DIF2="$(adjusted-value)"
  if [[ "$DIF2" =~ "error" ]]; then
    echo "$DIF2"
    echo "then subtract $DIF1 from that"
    echo "then add result to $OLD > $TRACKER"
    exit
  fi
  OLDNUM="$(echo $OLD | sed 's/\s\+[A-Za-z]iB//')"
  DIF1NUM="$(echo $DIF1 | sed 's/\s\+[A-Za-z]iB//')"
  DIF2NUM="$(echo $DIF2 | sed 's/\s\+[A-Za-z]iB//')"
  BYTE=""
  if [ "$OLDNUM" = "0" ] || [ "$OLDNUM" = "0.0" ]; then
    if [ "$DIF1NUM" = "0" ] || [ "$DIF1NUM" = "0.0" ]
    then BYTE="$(echo $DIF2 | sed 's/[0-9]*\.*[0-9]*\s\+//')"
    else
      BYTE="$(echo $DIF1 | sed 's/[0-9]*\.*[0-9]*\s\+//')"
      if [ "$BYTE" != "$(echo $DIF2 | sed 's/[0-9]*\.*[0-9]*\s\+//')" ] \
      && [ "$DIF2NUM" != "0" ] && [ "$DIF2NUM" != "0.0" ]; then
        echo "vnstat error: byte type mismatch"
        echo "compute $DIF2 - $DIF1 > $TRACKER"
        echo "and delete the \"paused at\" line"
        exit
      fi
    fi
  else
    BYTE="$(echo $OLD | sed 's/[0-9]*\.*[0-9]*\s\+//')"
    if ([ "$BYTE" != "$(echo $DIF1 | sed 's/[0-9]*\.*[0-9]*\s\+//')" ] \
    && [ "$DIF1NUM" != "0" ] && [ "$DIF1NUM" != "0.0" ]) \
    || ([ "$BYTE" != "$(echo $DIF2 | sed 's/[0-9]*\.*[0-9]*\s\+//')" ] \
    && [ "$DIF2NUM" != "0" ] && [ "$DIF2NUM" != "0.0" ]); then
      echo "vnstat error: byte type mismatch"
      echo "compute $DIF2 - $DIF1 + $OLD > $TRACKER"
      echo "and delete the \"paused at\" line"
      exit
    fi
  fi
  NEW="$(echo "$DIF2NUM-$DIF1NUM+$OLDNUM" | bc -l) $BYTE"
  echo $NEW > "$TRACKER"
  echo "$INTERFACE" >> "$TRACKER"
  echo "vnstat resumed with $DIF2 - $DIF1 + $OLD = $NEW ignored"
else
  NEW="$(adjusted-value)"
  if [[ "$NEW" =~ "error" ]]; then
    /usr/bin/vnstat
    echo "error: byte type mismatch: subtract $(sed -n 1p "$TRACKER")"
  else
    NEW="$(echo $NEW | sed 's/\s\+[A-Za-z]iB//')"
    /usr/bin/vnstat | grep -B99 "$INTERFACE" | head -n -1
    /usr/bin/vnstat | grep -A10 "$INTERFACE" | sed "s/\($(date +%b).*|.*|\s\+\)[0-9]*\.*[0-9]*\(\s\+[A-Za-z]iB\s\+|.*\)/\1$NEW\2/"
    /usr/bin/vnstat | grep -A99 "$INTERFACE" | tail -n +12
  fi
fi
