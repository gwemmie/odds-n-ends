#!/bin/bash
# Wrapper for youtube-dl to make video downloading easier for me, and
# eliminate the need of a browser to get to the video wherever possible.

# About half of the credit for this file goes to my brother, John Bove

# You have to run it with the --terminal option to make it not open up
# in a new terminal window. Why? Because I like to use YT2Player on
# Firefox to click on a Youtube video and immediately get a terminal
# window of youtube-dl downloading it.
# I suggest making a script called /usr/local/bin/video-dl that runs
# this script with the --terminal option.

# The other options are, you guessed it, the URL of the video, any extra
# folder inside of the destination you want it stored in (good for
# using the playlist feature to download a whole season), and any extra
# options to send straight to youtube-dl.

# Another feature is youtube annotations: it uses youtube-ass
# (https://github.com/nirbheek/youtube-ass) to get a .ass subtitle of
# the annotations and, if there are any annotations, saves the file
# with the same name as the video (otherwise deletes the file).

# Bonus feature: type "dailyshow" as the URL argument to automatically
# get the newest episode of the Daily Show with Trevor Noah. I wish I
# could do that with other shows as easily.
# That hasn't been working lately, because Comedy Central changed their
# site and doesn't update that redirect-to-newest-episode URL until at
# least 24 hours after the episode is available to stream.

# If you, like my brother, have a crippling monthly bandwidth limit, you
# can put the MAC address of your router in $LOWBAND to automatically
# download videos in 360p when you're home, and go for HD otherwise.
# That feature requires my mac-address.sh script and arping (from the
# package iputils) to be automatic. Otherwise, you can modify the script
# to just always download in 360p.
# Supported sites for automatic 360p are in that if-statement.
# Also can do automatic 720p with MEDBAND.

ROUTER="$(sudo $HOME/.dumbscripts/mac-address.sh $(ip route show match 0/0 | awk '{print $3}'))"
LOWBAND=( "00:0D:93:21:9D:F4" "14:DD:A9:D7:67:14" )
MEDBAND=( "08:86:3B:B4:EB:D4" )
TERMINAL=/usr/bin/mate-terminal
if [ "$1" = "--terminal" ]; then
  URL="$2"
  FOLDER="$3"
  EXOPT="${@:4}"
else
  URL="$1"
  FOLDER="$2"
  EXOPT="${@:3}"
fi
DEST="$HOME/Downloads/$FOLDER"

if [[ "$URL" =~ "youtube.com" ]]; then
  ID="$(echo $URL | cut -f 2 -d "=")"
  $HOME/.local/share/git/youtube-ass/youtube-ass.py "$ID"
  # check for empty annotations file
  # It's referred to with that wildcard in the beginning because once,
  # I somehow ended up with a file that had a hyphen in front of it (so
  # it was named "-$ID.ass" instead of just "$ID.ass", and so it didn't
  # get moved or deleted. I don't know why youtube-ass did that.
  # The double-hyphen makes it treat the file as a filename no matter
  # what. I had to do that because I've had to deal with files named
  # "--$ID.ass", which were interpreted as arguments. Why not just put
  # it in quotes? Because that made the wildcard stop being a wildcard.
  if [ "$(grep -A2 '\[Events\]' -- *$ID.ass | sed -n 3p)" = "" ]; then rm -- *$ID.ass
  else mv -- *$ID.ass "$DEST$ID.ass"
  fi
elif [[ "$URL" =~ "crunchyroll.com" ]]; then
  OPT="--write-sub --sub-lang enUS --recode-video mkv --embed-subs"
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "$URL")"
elif [ "$URL" = "dailyshow" ]; then
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "http://www.cc.com/shows/the-daily-show-with-trevor-noah/full-episodes")"
fi

# Plagiaraized from http://stackoverflow.com/questions/3685970/check-if-an-array-contains-a-value
function contains() {
  local n=$#
  local value=${!n}
  for ((i=1;i < $#;i++)) {
    if [ "${!i}" == "${value}" ]; then
      echo "y"
      return 0
    fi
  }
  echo "n"
  return 1
}

if [ $(contains "${LOWBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download low quality..."
  if [[ "$URL" =~ "youtube.com" ]] || [[ "$URL" =~ "youtu.be" ]]; then
    OPT="-f \"18/best[height<=360]\""
  elif [[ "$URL" =~ "vessel.com" ]]; then
    OPT="-f \"mp4-360-500K/best[height<=360]\""
  elif [[ "$URL" =~ "crunchyroll.com" ]]; then
    OPT="$OPT -f \"hls-meta-0/360p/best[height<=360]\""
  elif [[ "$URL" =~ "vimeo.com" ]]; then
    OPT="-f \"http-360p/best[height<=360]\""
  elif [[ "$URL" =~ "cc.com" ]]; then
    OPT="-f \"http-1028/1028/best[height<=360]\""
  elif [[ "$URL" =~ "ted.com" ]]; then
    OPT="-f \"http-1253/hls-1253/rtmp-600k/best[height<=360]\""
  elif [[ "$URL" =~ "cwseed.com" ]]; then
    OPT="-f \"hls-640/640/best[height<=360]\""
  else
    echo "WARNING: Unknown website. Defaulting to best quality."
    read -p "Download anyway? [Y/N] " ANS
     case $ANS in
       [nN]* ) exit;;
     esac
  fi
elif [ $(contains "${MEDBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download medium quality..."
  if [[ "$URL" =~ "youtube.com" ]] || [[ "$URL" =~ "youtu.be" ]]; then
    OPT="-f \"22/best[height<=720]/18/best[height<=360]\""
  elif [[ "$URL" =~ "vessel.com" ]]; then
    OPT="-f \"mp4-720-2400K/best[height<=720]/mp4-360-500K/best[height<=360]\""
  elif [[ "$URL" =~ "crunchyroll.com" ]]; then
    OPT="$OPT -f \"hls-meta-2/720p/best[height<=720]/hls-meta-1/480p/hls-meta-0/360p/best[height<=360]\""
  elif [[ "$URL" =~ "vimeo.com" ]]; then
    OPT="-f \"http-720p/best[height<=720]/http-360p/best[height<=360]\""
  elif [[ "$URL" =~ "cc.com" ]]; then
    OPT="-f \"http-3128/3128/best[height<=720]/http-1028/1028/best[height<=360]\""
  elif [[ "$URL" =~ "ted.com" ]]; then
    OPT="-f \"http-3976/hls-3976/rtmp-1500k/best[height<=720]/http-1253/hls-1253/rtmp-600k/best[height<=360]\""
  elif [[ "$URL" =~ "cwseed.com" ]]; then
    OPT="-f \"hls-2100/2100/best[height<=720]/hls-640/640/best[height<=360]\""
  else
    echo "WARNING: Unknown website. Defaulting to best quality."
    read -p "Download anyway? [Y/N] " ANS
     case $ANS in
       [nN]* ) exit;;
     esac
  fi
else echo "Trying to download high quality..."
fi

# the LC_ALL thing is to fix a bug where it needs LC_ALL to encode the
# filename properly
CMD="env LC_ALL=$LANG /usr/bin/youtube-dl $OPT ${EXOPT[@]} -o"

if [[ "$URL" =~ "cc.com" ]]; then
  CMD="$CMD \"$DEST%(title)s $ID.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "vessel.com" ]] || [[ "$URL" =~ "ted.com" ]] \
  || [[ "$URL" =~ "cwseed.com" ]]; then
  CMD="$CMD \"$DEST%(extractor)s - %(title)s $ID.%(ext)s\" \"$URL\""
else
  CMD="$CMD \"$DEST%(uploader)s - %(title)s $ID.%(ext)s\" \"$URL\""
fi

if [ "$1" != "--terminal" ]; then
  CMD="$TERMINAL --geometry=80x10 --title=youtube-dl -e '$(echo $CMD)'"
fi

eval "$CMD"
ERROR=$?

if [ "$ERROR" != 0 ]; then
  echo "Something went wrong"
  if [ "$1" != "--terminal" ]
  then read -n1 -r -p "Press any key to exit..."
  fi
  exit $ERROR
fi

if [[ "$URL" =~ "youtube.com" ]] && [ -f "$DEST$ID.ass" ]
then mv "$DEST$ID.ass" "$(find $DEST -name "*$ID.mp4" | sed -n 1p | sed 's/\.mp4/\.ass/')"
fi
