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
# options to send straight to youtube-dl. Other options include a
# compatibility check and telling the script to ask you how you want to
# handle the link. The proper order of the options goes:

# USAGE: download-vid.sh [--terminal|(--compatible)] (--compatible) URL
# [[destination subfolder]] [--ask] [extra options for youtube-dl]
# My own made-up usage notation:
# (parentheses) mean the argument is optional AND renders all of the
# optional arguments that come after it moot and useless.
# [[double brackets]] mean the argument is optional UNLESS you want to
# include the arguments that come after it. So, for the subfolder
# option, if you want to include extra options for youtube-dl, but don't
# want to specify a subfolder, you'll have to put a "./" in as its
# argument.

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

# Now has integration with browser.sh to automatically open video links
# that are compatible with this script according to YOUR choice at the
# time! Download, browser, or video player.

# Now also integrates with a new script, queue-dl, that queues up video
# downloads instead of downloading them all at once. For me,
# /usr/local/bin/queue-dl is a symlink to
# $HOME/.dumbscripts/download-vid-queue.sh, which is now a file in this
# git repo.

# Another new feature: if you feed it a text file with URLs separated by
# whitespace instead of a single URL, it will download each of those
# URLs in order, using queue-dl to (annoyingly) pop up a download window
# for each one. Currently not working.

# If you, like my brother, have a crippling monthly bandwidth limit, you
# can put the MAC address of your router in $LOWBAND to automatically
# download videos in 360p when you're home, and go for HD otherwise.
# That feature requires my mac-address.sh script and arping (from the
# package iputils) to be automatic. Otherwise, you can modify the script
# to just always download in 360p.
# Supported sites for automatic 360p are in that if-statement.
# Also can do automatic 720p with MEDBAND.

# New feature: backs up a list of your downloaded videos so that getting
# them back isn't a nightmare if your hard drive dies before you back it
# up.

ROUTER="$(ip neigh show $(ip route show match 0/0 | awk '{print $3}') | awk '{ print $5 }')"
LOWBAND=( "00:0d:93:21:9d:f4" "14:dd:a9:d7:67:14" )
MEDBAND=( "08:86:3b:b4:eb:d4" "44:e1:37:cb:2d:90" "b8:c7:5d:cb:75:1d" )
UKPROXY="91.229.222.163:53281" # taken from http://free-proxy-list.net/uk-proxy.html
DOWNLOADER=queue-dl
TERMINAL=/usr/bin/xfce4-terminal
BROWSER=$(grep BROWSER= $HOME/.dumbscripts/browser.sh | sed 's/BROWSER="\?\([^"]\+\)"\?/\1/')
PLAYER=/usr/bin/smplayer
if [ "$1" = "--terminal" ] || [ "$1" = "--compatible" ]; then
  if [ "$2" = "--compatible" ]; then
    URL="$3"
    FOLDER="$4"
    EXOPT="${@:5}"
  else
    URL="$2"
    FOLDER="$3"
    EXOPT="${@:4}"
  fi
else
  URL="$1"
  FOLDER="$2"
  if [ "$3" = "--ask" ]
  then EXOPT="${@:4}"
  else EXOPT="${@:3}"
  fi
fi
if [[ "$URL" =~ "crunchyroll.com" ]] || [[ "$URL" =~ "cc.com" ]] \
|| [[ "$URL" =~ "cwseed.com" ]] || [[ "$URL" =~ "bbc.co.uk" ]] \
|| [[ "$URL" =~ "uktvplay.uktv.co.uk" ]]
then DEST="$HOME/Downloads/Ongoing TV/$FOLDER"
else DEST="$HOME/Downloads/$FOLDER"
fi
ROOSTER_TEETH="false"
# text file queue mode--not working because of weird quote issues
#if [ -f "$URL" ]; then
#  FILE="$URL"
#  readarray URLS <"$FILE"
#  for URL in "${URLS[@]}"; do
#  URL="$(echo -n "$URL")" # readarray leaves the newline in there
#  nohup $HOME/.dumbscripts/download-vid.sh "$URL" "$FOLDER" "$EXOPT" >/dev/null & sleep 0.5
#  done
#  exit 0
#fi

function compatibility_check {
  echo -n "Checking for compatibility... "
  if [[ "$URL" =~ "youtube.com" ]] || [[ "$URL" =~ "youtu.be" ]] \
  || [[ "$URL" =~ "cinemassacre.com" ]] || [[ "$URL" =~ "channelawesome.com" ]] \
  || [[ "$URL" =~ "teamfourstar.com" ]] \
  || [[ "$URL" =~ "vessel.com" ]] \
  || [[ "$URL" =~ "dailymotion.com" ]] \
  || [[ "$URL" =~ "crunchyroll.com" ]] \
  || [[ "$URL" =~ "vimeo.com" ]] \
  || [[ "$URL" =~ "cc.com" ]] \
  || [[ "$URL" =~ "ted.com" ]] \
  || [[ "$URL" =~ "cwseed.com" ]] \
  || [[ "$URL" =~ "bbc.co.uk" ]] \
  || [[ "$URL" =~ "uktvplay.uktv.co.uk" ]] \
  || [[ "$URL" =~ "vid.me" ]] \
  || [ "$ROOSTER_TEETH" = "true" ]
  then
    echo "Website is compatible"
    exit 0
  else
    echo "Unknown website"
    exit 1
  fi
}

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

# per-site miscellaneous extra params that have to happen before compatibility check
if [[ "$URL" =~ "youtube.com" ]]; then
  OPT="--cookies $HOME/.dumbscripts/download-vid-cookies.txt"
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
  if [ -z "$(grep -A2 '\[Events\]' -- *$ID.ass | sed -n 3p)" ]; then rm -- *$ID.ass
  else mv -- *$ID.ass "$DEST$ID.ass"
  fi
  if [ -z "$(grep -A2 '\[Events\]' -- *$ID.ssa | sed -n 3p)" ]; then rm -- *$ID.ssa
  else mv -- *$ID.ssa "$DEST$ID.ssa"
  fi
elif [[ "$URL" =~ "crunchyroll.com" ]]; then
  OPT="--write-sub --sub-lang enUS --recode-video mkv --postprocessor-args "-c:copy" --embed-subs"
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "$URL")"
elif [ "$URL" = "dailyshow" ]; then
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "http://www.cc.com/shows/the-daily-show-with-trevor-noah/full-episodes")"
elif [[ "$URL" =~ "bbc.co.uk" ]] \
  || [[ "$URL" =~ "uktvplay.uktv.co.uk" ]]; then
  OPT="--proxy \"$UKPROXY\""
  DEST="${DEST}iplayer-temp/"
elif [[ "$URL" =~ "roosterteeth.com" ]]; then
  if ! hash jq 2>/dev/null ; then
    echo "ERROR: roosterteeth.com support requires jq"
    exit 1
  fi
  # just to make the following checks not break if $URL is just "roosterteeth.com/etc"
  if ! [[ "$URL" =~ "http" ]]
  then URL="https://$URL"
  fi
  TITLE="$(echo "$URL" | sed 's|https\?://roosterteeth.com/episode/\([^/]\+\)|\1|')"
  if echo "$TITLE" | grep -E "https?://roosterteeth.com/" || [ -z "$TITLE" ]; then
    echo "ERROR: Couldn't get Rooster Teeth video title"
    exit 1
  fi
  # capitalize and replace hyphens '-' with spaces ' ', so "camp-camp-episode-3' becomes 'Camp Camp Episode 3'
  TITLE="$(echo "$TITLE" | sed 's/^\(.\)/\u\1/' | sed 's/-\(.\)/ \u\1/g')"
  API_URL="$(echo "$URL" | sed 's|roosterteeth.com/episode/\(.\+\)|svod-be.roosterteeth.com/api/v1/episodes/\1/videos|')"
  URL="$(curl "$API_URL" 2>/dev/null | jq -r '.data[].attributes[]' | grep http)"
  if echo "$URL" | grep -E "https?://roosterteeth.com/" || [ -z "$URL" ] \
  || [[ "$URL" =~ "parse error" ]]; then
    echo "ERROR: Couldn't get Rooster Teeth API URL" | tee "${DEST}Rooster Teeth - $TITLE"
    echo "\$API_URL=$API_URL" >> "${DEST}Rooster Teeth - $TITLE"
    exit 1
  fi
  # we no longer know exactly what the roosterteeth.com URL is, so we have to keep track a simpler way when it comes to later options
  ROOSTER_TEETH="true"
fi

if [ "$2" = "--compatible" ]
then compatibility_check # will result in an exit after execution
fi

# per-site quality params
if [ $(contains "${LOWBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download low quality..."
  if [[ "$URL" =~ "youtube.com" ]] || [[ "$URL" =~ "youtu.be" ]]; then
    OPT="$OPT -f \"18/43/best[height<=480]\""
  elif [[ "$URL" =~ "cinemassacre.com" ]] \
  || [[ "$URL" =~ "channelawesome.com" ]]; then
    OPT="-f \"480p/best[height<=360]\""
  elif [[ "$URL" =~ "teamfourstar.com" ]]; then
    OPT="-f \"dash-video-avc1-1+dash-audio-und-mp4a-3/best[height<=360]\""
  elif [[ "$URL" =~ "vessel.com" ]]; then
    OPT="-f \"mp4-360-500K/best[height<=360]\""
  elif [[ "$URL" =~ "dailymotion.com" ]]; then
    OPT="-f \"http-380/best[height<=380]\""
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
  elif [[ "$URL" =~ "bbc.co.uk" ]]; then
    OPT="$OPT -f \"best[height<=380]\""
  elif [[ "$URL" =~ "uktvplay.uktv.co.uk" ]]; then
    OPT="$OPT -f \"best[height<=380]\""
  elif [[ "$URL" =~ "vid.me" ]]; then
    OPT="$OPT -f \"dash-video-avc1-1+dash-audio-und-mp4a-1\""
  elif [ "$ROOSTER_TEETH" = "true" ]; then
    OPT="-f \"best[height<=360]\""
  else
    echo "WARNING: Unknown website. May not get desired quality."
    OPT="-f \"best[height<=360]\""
    # commented out because I was sick of not being able to leave a
    # batch downloading unattended
    #read -p "Download anyway? [Y/N] " ANS
    # case $ANS in
    #   [nN]* ) exit;;
    # esac
  fi
  QUALITY=$(echo $OPT | sed 's/.*-f "\(.*\)".*/\1/')
  #sed -i "s/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=$QUALITY/" $HOME/.config/smplayer/smplayer.ini
elif [ $(contains "${MEDBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download medium quality..."
  if [[ "$URL" =~ "youtube.com" ]] || [[ "$URL" =~ "youtu.be" ]]; then
    OPT="$OPT -f \"720p/best[height<=720]/480p/best[height<=480]\""
  elif [[ "$URL" =~ "cinemassacre.com" ]] \
  || [[ "$URL" =~ "channelawesome.com" ]]; then
    OPT="-f \"720p/best[height<=720]/480p/best[height<=360]\""
  elif [[ "$URL" =~ "teamfourstar.com" ]]; then
    OPT="-f \"dash-video-avc1-3+dash-audio-und-mp4a-3/best[height<=720]/dash-video-avc1-1+dash-audio-und-mp4a-3/best[height<=360]\""
  elif [[ "$URL" =~ "vessel.com" ]]; then
    OPT="-f \"mp4-720-2400K/best[height<=720]/mp4-360-500K/best[height<=360]\""
  elif [[ "$URL" =~ "dailymotion.com" ]]; then
    OPT="-f \"http-780/best[height<=780]/http-380/best[height<=380]\""
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
  elif [[ "$URL" =~ "bbc.co.uk" ]]; then
    OPT="$OPT -f \"best[height<=720]\""
  elif [[ "$URL" =~ "uktvplay.uktv.co.uk" ]]; then
    OPT="$OPT -f \"best[height<=720]\""
  elif [[ "$URL" =~ "vid.me" ]]; then
    OPT="$OPT -f \"dash-video-avc1-3+dash-audio-und-mp4a-1\""
  elif [ "$ROOSTER_TEETH" = "true" ]; then
    OPT="-f \"best[height<=720]\""
  else
    echo "WARNING: Unknown website. May not get desired quality."
    OPT="-f \"best[height<=720]\""
    # commented out because I was sick of not being able to leave a
    # batch downloading unattended
    #read -p "Download anyway? [Y/N] " ANS
    # case $ANS in
    #   [nN]* ) exit;;
    # esac
  fi
  QUALITY=$(echo $OPT | sed 's/.*-f "\(.*\)".*/\1/')
  #sed -i "s/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=$QUALITY/" $HOME/.config/smplayer/smplayer.ini
else
  #sed -i 's/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=/' $HOME/.config/smplayer/smplayer.ini
  echo "Trying to download high quality..."
fi

# the LC_ALL thing is to fix a bug where it needs LC_ALL to encode the
# filename properly
CMD="env LC_ALL=$LANG $DOWNLOADER $OPT ${EXOPT[@]} -o"

# per-site destination params
if [[ "$URL" =~ "cc.com" ]]
then CMD="$CMD \"${DEST}%(title)s $ID.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "vessel.com" ]] || [[ "$URL" =~ "ted.com" ]] \
  || [[ "$URL" =~ "cwseed.com" ]]
then CMD="$CMD \"${DEST}%(extractor)s/%(title)s $ID.%(ext)s\" \"$URL\""
elif [ "$ROOSTER_TEETH" = "true" ]
then CMD="$CMD \"${DEST}Rooster Teeth/$TITLE.%(ext)s\" \"$URL\""
elif [ -z "$FOLDER" ] || [ "$FOLDER" = "./" ]
then CMD="$CMD \"${DEST}%(uploader)s/%(title)s $ID.%(ext)s\" \"$URL\""
else CMD="$CMD \"${DEST}%(uploader)s - %(title)s $ID.%(ext)s\" \"$URL\""
fi

if [ "$1" != "--terminal" ]; then
  if [ "$1" = "--compatible" ]
  then CMD="$HOME/.dumbscripts/download-vid.sh --terminal --compatible \"$URL\"; cat"
  elif [ "$3" = "--ask" ]; then
    echo "#!/bin/bash" >/tmp/download-vid-ask.sh
    chmod +x /tmp/download-vid-ask.sh
    echo 'while true; do' | tee -a /tmp/download-vid-ask.sh
    echo '  read -n 1 -p "Download, browser, player, copy link, or quit? [D/B/P/C/Q] " ANS' | tee -a /tmp/download-vid-ask.sh
    echo '  case $ANS in' | tee -a /tmp/download-vid-ask.sh
    echo '    [dD] )' "echo; $CMD; break;;" | tee -a /tmp/download-vid-ask.sh
    echo '    [bB] )' "nohup $BROWSER \"$URL\" >/dev/null & sleep 0.5; break;;" | tee -a /tmp/download-vid-ask.sh
    echo '    [pP] )' "nohup $PLAYER \"$URL\" >/dev/null & sleep 0.5; break;;" | tee -a /tmp/download-vid-ask.sh
    echo '    [cC] )' "echo -n \"$URL\" | xclip -selection c; sleep 0.5; break;;" | tee -a /tmp/download-vid-ask.sh
    echo '    [qQ] ) break;;' | tee -a /tmp/download-vid-ask.sh
    echo '       * ) echo "invalid option"' | tee -a /tmp/download-vid-ask.sh
    echo '  esac' | tee -a /tmp/download-vid-ask.sh
    echo 'done' | tee -a /tmp/download-vid-ask.sh
    echo 'rm /tmp/download-vid-ask.sh' | tee -a /tmp/download-vid-ask.sh
    CMD="/tmp/download-vid-ask.sh"
  fi
  CMD="$TERMINAL --geometry=80x10 --title=youtube-dl -e \"bash -c '$(echo $CMD)'\""
fi

eval "$CMD" &
wait $!
ERROR=$?

if [ "$ERROR" != 0 ] && [ "$ERROR" != 255 ]; then
  echo "Something went wrong"
  if [ "$1" != "--terminal" ]
  then read -n1 -r -p "Press any key to exit..."
  fi
  exit $ERROR
fi

ls --group-directories-first $HOME/Downloads > $HOME/Dropbox/Settings/Scripts/Downloads

if [[ "$URL" =~ "youtube.com" ]] && [ -f "$DEST$ID.ass" ]; then
  mv "$DEST$ID.ass" "$(find $DEST -name "*$ID.mp4" | sed -n 1p | sed 's/\.mp4/\.ass/')"
elif [[ "$URL" =~ "bbc.co.uk" ]]; then
  mv "$(ls "${DEST}*.mkv")" $HOME/Downloads/
  rmdir "$DEST"
fi

# my own script to automate some folder management with downloaded videos
$HOME/.dumbscripts/update-downloads.sh & disown

disown -r && exit
