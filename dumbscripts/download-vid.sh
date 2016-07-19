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

# If you, like my brother, have a crippling monthly bandwidth limit, you
# can put the MAC address of your router in $LOWBAND to automatically
# download videos in 360p when you're home, and go for HD otherwise.
# That feature requires my mac-address.sh script and arping (from the
# package iputils) to be automatic. Otherwise, you can modify the script
# to just always download in 360p.
# Supported sites for automatic 360p:
# YouTube
# Vessel (Channel Awesome)
# Crunchyroll
# Vimeo
# Comedy Central
# TED Talks
# The CW

ROUTER="$(sudo $HOME/.dumbscripts/mac-address.sh $(ip route show match 0/0 | awk '{print $3}'))"
LOWBAND=( "00:0D:93:21:9D:F4" "14:DD:A9:D7:67:14" )
TERMINAL=/usr/bin/mate-terminal
if [ "$1" = "--terminal" ]; then
  URL="$2"
  FOLDER="$3"
  EXOPT="$4"
else
  URL="$1"
  FOLDER="$2"
  EXOPT="$3"
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
  if [[ "$URL" =~ "youtube.com" ]]; then
    OPT="-f 18"
  elif [[ "$URL" =~ "vessel.com" ]]; then
    OPT="-f mp4-360-500K"
  elif [[ "$URL" =~ "crunchyroll.com" ]]; then
    OPT="$OPT -f 360p"
  elif [[ "$URL" =~ "vimeo.com" ]]; then
    OPT="-f http-360p"
  elif [[ "$URL" =~ "cc.com" ]]; then
    OPT="-f 1028"
  elif [[ "$URL" =~ "ted.com" ]]; then
    OPT="-f rtmp-600k"
  elif [[ "$URL" =~ "cwseed.com" ]]; then
    OPT="-f 640"
  else
    echo "WARNING: Unknown website. Defaulting to best quality."
    read -p "Download anyway? [Y/N] " ANS
     case $ANS in
       [nN]* ) exit;;
     esac
  fi
  else echo "Trying to download high quality..."
fi

CMD="/usr/bin/youtube-dl $OPT $EXOPT -o"

if [[ "$URL" =~ "cc.com" ]]; then
  CMD="$CMD \"$DEST%(title)s $ID.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "vessel.com" ]] || [[ "$URL" =~ "cwseed.com" ]]; then
  CMD="$CMD \"$DEST%(extractor)s - %(title)s $ID.%(ext)s\" \"$URL\""
else
  CMD="$CMD \"$DEST%(uploader_id)s - %(title)s $ID.%(ext)s\" \"$URL\""
fi

if [ "$1" != "--terminal" ]; then
  CMD="$TERMINAL --geometry=80x10 --title=youtube-dl -e '$(echo $CMD)'"
fi

eval "$CMD"

if [ "$?" != 0 ]; then
  echo "Something went wrong"
  if [ "$1" != "--terminal" ]
  then read -n1 -r -p "Press any key to exit..."
  fi
fi

if [[ "$URL" =~ "youtube.com" ]] && [ -f "$DEST$ID.ass" ]
then mv "$DEST$ID.ass" "$(find $DEST -name "*$ID.mp4" | sed -n 1p | sed 's/\.mp4/\.ass/')"
fi
