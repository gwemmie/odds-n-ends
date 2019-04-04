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
# download videos in 480p when you're home, and go for HD otherwise.
# That feature requires my mac-address.sh script and arping (from the
# package iputils) to be automatic. Otherwise, you can modify the script
# to just always download in 480p.
# Supported sites for automatic 480p are in that if-statement.
# Also can do automatic 720p with MEDBAND.
# Here's a list of sites in which I made LOWBAND point to 720p instead,
# because the sound quality of 480p was bad:
# bbcamerica.com

# Another new feature: Dish provider login support, via a branch that
# isn't merged yet. It isn't merged because it doesn't work on plenty of
# sites yet. However, it does work with the sites I've chosen to use it
# on here. If you use a different provider to login, you can change or
# delete the code that changes $DOWNLOADER, and the "per-site misc extra
# params", for the following provider-login websites:
# bbcamerica.com
# history.com

ROUTER="$(ip neigh show $(ip route show match 0/0 | awk '{print $3}') | awk '{ print $5 }')"
LOWBAND=( "00:0d:93:21:9d:f4" "14:dd:a9:d7:67:14" "00:25:9c:c1:63:b1" "1c:87:2c:d3:bd:bc" )
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
# we will soon lose track of exactly what the roosterteeth.com URL is, so we have to keep track a simpler way when it comes to later options
ROOSTER_TEETH="false"
if [[ "$URL" =~ "crunchyroll.com" ]] || [[ "$URL" =~ "cc.com" ]] \
|| [[ "$URL" =~ "cwseed.com" ]] || [[ "$URL" =~ "bbcamerica.com" ]] \
|| [[ "$URL" =~ "history.com" ]]
then DEST="$HOME/Downloads/Ongoing TV/$FOLDER"
elif [[ "$URL" =~ "roosterteeth.com" ]]; then
  ROOSTER_TEETH="true"
  DEST="$HOME/Downloads/Rooster Teeth/$FOLDER"
else DEST="$HOME/Downloads/$FOLDER"
fi
if [[ "$URL" =~ "bbcamerica.com" ]] || [[ "$URL" =~ "history.com" ]]
then DOWNLOADER='queue-dl --branch Dish'
fi
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
  || [[ "$URL" =~ "bbcamerica.com" ]] \
  || [[ "$URL" =~ "history.com" ]] \
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

# this function will be used by another temp sh file
cat >/tmp/download-vid-error.sh <<\EOF
#!/bin/bash
function error_handling() { # args: (error code, $DOWNLOADER, $CMD, [--terminal])
  if [ "$1" != 0 ] && [ "$1" != 255 ]; then
    echo
    echo "ERROR: Something went wrong with $2"
    echo "Command attempted: $3"
    echo
    if [ "$4" != "--terminal" ]; then
      read -n1 -r -p "Press any key to exit..."
      echo
    fi
    exit $1
  fi
  rm /tmp/download-vid-error.sh
}
EOF
chmod +x /tmp/download-vid-error.sh
source /tmp/download-vid-error.sh

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
  if [ -z "$(grep -A2 '\[Events\]' -- *$ID.ass 2>/dev/null | sed -n 3p)" ]
  then rm -- *$ID.ass
  else mv -- *$ID.ass "$DEST$ID.ass"
  fi
  if [ -z "$(grep -A2 '\[Events\]' -- *$ID.ssa 2>/dev/null | sed -n 3p)" ]
  then rm -- *$ID.ssa
  else mv -- *$ID.ssa "$DEST$ID.ssa"
  fi
elif [[ "$URL" =~ "crunchyroll.com" ]]; then
  OPT="--write-sub --sub-lang enUS --recode-video mkv --postprocessor-args \"-c copy\" --embed-subs"
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "$URL")"
elif [ "$URL" = "dailyshow" ]; then
  URL="$(curl -LIs -o /dev/null -w '%{url_effective}' "http://www.cc.com/shows/the-daily-show-with-trevor-noah/full-episodes")"
# I give up
#elif [[ "$URL" =~ "bbc.co.uk" ]] \
#  || [[ "$URL" =~ "uktvplay.uktv.co.uk" ]]; then
#  OPT="--proxy \"$UKPROXY\""
#  DEST="${DEST}iplayer-temp/"
elif [[ "$URL" =~ "bbcamerica.com" ]] || [[ "$URL" =~ "history.com" ]]; then
  OPT="--ap-mso Dish --ap-username bove@mcn.org --ap-password $(gkeyring --name 'dish' --keyring login -o secret)"
  if [[ "$URL" =~ "history.com" ]]
  # capitalize show name and reduce season/episode numbers, so "vikings/season-5/episode-15' becomes 'Vikings 515'
  then TITLE="$(echo "$URL" | sed 's|https\?://\(www.\)\?history.com/shows/\([^/]\+\)/season-\([0-9]\+\)/episode-\([0-9]\+\).*|\u\2 \3\4|')"
  fi
elif [ "$ROOSTER_TEETH" = "true" ]; then
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
    echo "ERROR: Couldn't get Rooster Teeth API URL" | tee "${DEST}$TITLE"
    echo "\$API_URL=$API_URL" >> "${DEST}$TITLE"
    exit 1
  fi
fi

if [ "$2" = "--compatible" ]
then compatibility_check # will result in an exit after execution
fi

# per-site quality params
if [ $(contains "${LOWBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download low quality..."
  if [[ "$URL" =~ "crunchyroll.com" ]]; then
    # to avoid getting subs embedded in video stream
    OPT="$OPT -f \"best[height<=480][format_id*=audio-jaJP]\""
  elif [[ "$URL" =~ "teamfourstar.com" ]] \
    || [[ "$URL" =~ "vid.me" ]]; then
    # have to combine separate video/audio streams that aren't marked properly for youtube-dl to handle automatically
    OPT="$OPT -f \"dash-video-avc1-1+dash-audio-und-mp4a-1/dash-video-avc1-1+dash-audio-und-mp4a-3/best[height<=480]\""
  elif [[ "$URL" =~ "bbcamerica.com" ]]
    # the sound quality for 480p is bad, and bad sound quality is simply not
    # worth obeying bandwidth limits
  then OPT="$OPT -f \"best[height<=720]\""
  else
    OPT="$OPT -f \"best[height<=480]\""
  fi
  QUALITY=$(echo $OPT | sed 's/.*-f "\(.*\)".*/\1/')
  # wasn't doing anything for some reason
  #sed -i "s/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=$QUALITY/" $HOME/.config/smplayer/smplayer.ini
elif [ $(contains "${MEDBAND[@]}" "$ROUTER") = "y" ]; then
  echo "Trying to download medium quality..."
  if [[ "$URL" =~ "crunchyroll.com" ]]; then
    OPT="$OPT -f \"best[height<=720][format_id*=audio-jaJP]/best[height<=480][format_id*=audio-jaJP]\""
  elif [[ "$URL" =~ "teamfourstar.com" ]] \
    || [[ "$URL" =~ "vid.me" ]]; then
    # have to combine separate video/audio streams that aren't marked properly for youtube-dl to handle automatically
    OPT="$OPT -f \"dash-video-avc1-3+dash-audio-und-mp4a-1/dash-video-avc1-3+dash-audio-und-mp4a-3/best[height<=720]/dash-video-avc1-1+dash-audio-und-mp4a-1/dash-video-avc1-1+dash-audio-und-mp4a-3/best[height<=480]\""
  else
    OPT="$OPT -f \"best[height<=720]/best[height<=480]\""
  fi
  QUALITY=$(echo $OPT | sed 's/.*-f "\(.*\)".*/\1/')
  # wasn't doing anything for some reason
  #sed -i "s/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=$QUALITY/" $HOME/.config/smplayer/smplayer.ini
else
  # wasn't doing anything for some reason
  #sed -i 's/streaming\\youtube\\quality=.*/streaming\\youtube\\quality=/' $HOME/.config/smplayer/smplayer.ini
  echo "Trying to download high quality..."
fi

# the LC_ALL thing is to fix a bug where it needs LC_ALL to encode the
# filename properly
CMD="env LC_ALL=$LANG $DOWNLOADER $OPT ${EXOPT[@]} -o"

# per-site destination params
if [[ "$URL" =~ "cc.com" ]] || [[ "$URL" =~ "crunchyroll.com" ]]
then CMD="$CMD \"${DEST}%(title)s $ID.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "bbcamerica.com" ]]
then CMD="$CMD \"${DEST}%(title)s.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "history.com" ]]
then CMD="$CMD \"${DEST}$TITLE %(title)s.%(ext)s\" \"$URL\""
elif [ "$ROOSTER_TEETH" = "true" ]
then CMD="$CMD \"${DEST}$TITLE.%(ext)s\" \"$URL\""
elif [[ "$URL" =~ "vessel.com" ]] || [[ "$URL" =~ "ted.com" ]] \
  || [[ "$URL" =~ "cwseed.com" ]]
then CMD="$CMD \"${DEST}%(extractor)s/%(title)s $ID.%(ext)s\" \"$URL\""
elif [ -z "$FOLDER" ] || [ "$FOLDER" = "./" ]
then CMD="$CMD \"${DEST}%(uploader)s/%(title)s $ID.%(ext)s\" \"$URL\""
else CMD="$CMD \"${DEST}%(uploader)s - %(title)s $ID.%(ext)s\" \"$URL\""
fi

if [ "$1" != "--terminal" ]; then
  if [ "$1" = "--compatible" ]
  then CMD="$HOME/.dumbscripts/download-vid.sh --terminal --compatible \"$URL\"; cat"
  elif [ "$3" = "--ask" ]; then
    cat >/tmp/download-vid-ask.sh <<EOF
#!/bin/bash
source /tmp/download-vid-error.sh
while true; do
  read -n 1 -p "Download, browser, player, copy link, or quit? [D/B/P/C/Q] " ANS
  case \$ANS in
    [dD] ) echo; $CMD; ERROR=\$?; break;;
    [bB] ) nohup $BROWSER "$URL" >/dev/null & sleep 0.5; disown -r & exit; break;;
    [pP] ) nohup $PLAYER "$URL" >/dev/null & sleep 0.5; disown -r & exit; break;;
    [cC] ) echo -n "$URL" | xclip -selection c; sleep 0.5; disown -r & exit; break;;
    [qQ] ) disown -r & exit; break;;
       * ) echo; echo "invalid option"
  esac
done
error_handling \$ERROR "$DOWNLOADER" '$CMD'
rm /tmp/download-vid-ask.sh
EOF
    chmod +x /tmp/download-vid-ask.sh
    CMD="/tmp/download-vid-ask.sh"
  fi
  CMD="$TERMINAL --geometry=80x10 --title=youtube-dl -e \"bash -c '$(echo $CMD)'\""
fi

eval "$CMD" &
wait $!
ERROR=$?

error_handling $ERROR "$DOWNLOADER" "$CMD" --terminal

ls --group-directories-first $HOME/Downloads > $HOME/Dropbox/Settings/Scripts/Downloads

if [[ "$URL" =~ "youtube.com" ]] && [ -f "$DEST$ID.ass" ]; then
  mv "$DEST$ID.ass" "$(find $DEST -name "*$ID.mp4" | sed -n 1p | sed 's/\.mp4/\.ass/')"
elif [[ "$URL" =~ "bbc.co.uk" ]]; then
  mv "$(ls "${DEST}*.mkv")" $HOME/Downloads/
  rmdir "$DEST"
fi

# my own script to automate some folder management with downloaded videos
$HOME/.dumbscripts/update-downloads.sh >/dev/null 2>&1 & disown

disown -r && exit
