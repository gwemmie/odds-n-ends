#!/bin/bash
# Upon switching from GMail's web client to Thunderbird, *after* Thunderbird upgraded to
# Quantum and therefore lost any ability at all to have some sort of decent tray icon
# (but I do really prefer Quantum in my Mozilla products FTR), I had to figure something out.
#---------------------------------------BEGIN RANT--------------------------------------------
# The XFCE applet for mail notification was decent, but it refuses to not take up every row
# of whatever panel it's on. I use a 3-row panel, so that huge icon taking up way too much
# space was just not a viable solution. From there, I tried every damn third-party mail notifier
# in the Arch repos and AUR, and every last one had at least one, almost always 2+, of these
# problems, enough to be a dealbreaker every single time:
# - the entirety of GNOME, KDE/Plasma, or Cinnamon as dependencies (sucky but not a dealbreaker)
# - missing functionality I need, such as clicking the icon to open a program of my choice,
#   having a different icon when anything's unread (seriously!), having an icon present when
#   nothing's unread, and having any sort of systray icon support whatsoever (seriously!)
# - hasn't been updated since 2015 at the latest (sucky but not a dealbreaker)
# - hasn't been updated in so long that it isn't even compatible with GMail anymore
# I'll give hasmail credit for mostly not having these flaws (at least less than the others),
# but its limited amount of options left a bit to be desired. Mainly I just couldn't see
# myself ever getting used to its weird choice of icons and associating them with e-mail.
#----------------------------------------END RANT---------------------------------------------
# So, finally after spending all day breaking down from desperation, I learned about yad and
# GMail's atom feed and made my own dang mail notify program, with blackjack (BASH), and hookers
# (hashes)

# Config variables--change these to fit your needs
MAILPROG=thunderbird
ICON="gmail-offline"
UNREADICON="gmail"
DOMAIN="gmail.com"
USERNAME="JimiJames.Bove"
PASSWORD=$(gkeyring --name 'gmail' --keyring login -o secret)
INTERVAL=600 # half-seconds
RETRY=30 # how many times to retry connecting before giving up
NOTIFY="false" # whether to send new message subjects to libnotify
# $CHECKCMD must output email subject and ID, in that order, separated by newlines
# you're welcome to change that--I just set it up that way because it was easiest with parsing a GMail atom feed
# $TESTCMD is for testing the connection
TESTCMD="curl -sSu $USERNAME:$PASSWORD \"https://mail.google.com/mail/feed/atom\""
CHECKCMD="curl -su $USERNAME:$PASSWORD \"https://mail.google.com/mail/feed/atom\" | grep -oPm1 \"(?<=<title>|<id>)[^<]+\" | grep -vi \"Gmail - Inbox for $USERNAME@$DOMAIN\""
# yad menu syntax was a really stupid amount of hard to find--wasn't even in their own docs!
# (at least not clearly)
# it goes "<menu item string>! <menu item command>|<subsequent>|<menu>|<items>..."
# at least their docs say how to change the ! and | to different characters if you prefer
DEFAULTMENU="Check for messages...! $0 recheck"
DEFAULTMENU+="|Run ${MAILPROG}! $0 launch"
LOCKFILE="$(dirname $0)/$(basename $0 | sed 's/\.sh//')-lock"
PIPEFILE="/tmp/$(basename $0 | sed 's/\.sh//')-yad-input"
MAILFILE="$(dirname $0)/$(basename $0 | sed 's/\.sh//')-messages"

# Temp variables--used by the program and changing per run
NEWMESSAGES=()
YADPID=""

# Functions
function error() {
  ERROR="ERROR: $1"
  echo "$(basename $0): $ERROR"
  notify-send -a "$(basename $0)" "$(basename $0)" "$ERROR"
  stop
  exit $2
}
function messages-set() {
  ID="$1"
  SUBJECT="$2"
  echo "ID: $ID" >> "$MAILFILE"
  echo "SUBJECT: $SUBJECT" >> "$MAILFILE"
}
function messages-get() {
  ID="$1"
  if [ "$1" = "--test" ]
  then ID="$2"
  fi
  if grep -q "$ID" "$MAILFILE" 2>/dev/null \
  && grep -A1 "$ID" "$MAILFILE" 2>/dev/null | grep -qx 'SUBJECT: .*' 2>/dev/null
  then grep -A1 "$ID" "$MAILFILE" | tail -1 | sed 's/^SUBJECT: //'
  else if [ "$1" = "--test" ]
    then return 1
    else error "tried to get nonexistent message ID or ID is missing subject" 1
    fi
  fi
  return 0
}
function messages-contains() {
  if messages-get --test "$1" >/dev/null
  then return 0
  else return 1
  fi
}
function messages-unset() {
  if messages-contains "$1"; then
    ID_LINE="$(grep "$1" "$MAILFILE")"
    SUBJECT_LINE="$(grep -A1 "$1" "$MAILFILE" | tail -1 | sed 's/^SUBJECT: //')"
    sed -i "/$ID_LINE/d" "$MAILFILE"
    sed -i "/$SUBJECT_LINE/d" "$MAILFILE"
  fi
}
function messages-get-all { # prints all IDs
  grep -x 'ID: .*' "$MAILFILE" | sed 's/^ID: //'
}
function messages-length {
  messages-get-all | wc -l
}
function send-command() {
  echo -e "$@\n" > "$PIPEFILE"
}
function set-read {
  send-command "icon:$ICON"
  send-command "tooltip:$USERNAME@$DOMAIN - no new messages"
  send-command "menu:$DEFAULTMENU"
}
function set-unread() {
  send-command "icon:$UNREADICON"
  send-command "tooltip:$USERNAME@$DOMAIN - $1 new messages"
  MENU="$DEFAULTMENU|-"
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for ID in $(messages-get-all)
  do MENU+="|$(messages-get "$ID")"
  done
  IFS=$SAVEIFS
  send-command "menu:$MENU"
}
function stop {
  if ps $YADPID >/dev/null; then
    send-command "quit"
    wait $YADPID
  fi
  rm "$MAILFILE"
  rm "$PIPEFILE"
  rm "$LOCKFILE"
}
function start {
  touch "$LOCKFILE"
  > "$MAILFILE"
  mkfifo "$PIPEFILE"
  tail -f "$PIPEFILE" | yad --notification --text="$USERNAME@$DOMAIN" --command="$0 launch" --image="$ICON" --listen 2>/dev/null &
  YADPID=$!
  send-command "menu:Starting up..."
}
function reset { # AKA mark current messages as read until next check
  stop
  NEWMESSAGES=()
  YADPID=""
  start
  set-read
}
function poll {
  COUNTER=0
  while [ $COUNTER -lt $INTERVAL ]; do
    if ! [ -e "$LOCKFILE" ]; then
      stop
      disown -r && exit
    elif ! ps $YADPID >/dev/null; then
      stop
      disown -r && exit
    elif [ "$(<"$LOCKFILE")" = "reset" ]; then
      > "$LOCKFILE"
      > "$MAILFILE"
      COUNTER=0
      reset
    elif [ "$(<"$LOCKFILE")" = "recheck" ]; then
      > "$LOCKFILE"
      break;
    fi
    sleep 0.5
    let COUNTER+=1
  done
}
function test-connection {
  OUTPUT=""
  TEST=1
  COUNTER=0
  while [ $COUNTER -lt $RETRY ]; do
    OUTPUT="$(eval "$TESTCMD" >/dev/null)"
    TEST=$?
    if [ $TEST -ne 0 ]
    then let COUNTER+=1
    else return 0
    fi
  done
  error "$OUTPUT" $TEST # results in exit
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

# Script begins
if ! hash yad 2>/dev/null
then error "this script requires yad (and recommends gkeyring)" 1 # results in exit
fi

if [ "$1" = "launch" ]; then
  echo "reset" > "$LOCKFILE"
  # yes, it actually took this many disowns to make the script not wait for $MAILPROG to close!
  eval "$MAILPROG & disown" & disown
  disown -r && exit
elif [ "$1" = "recheck" ]; then
  echo "recheck" > "$LOCKFILE"
  disown -r && exit
elif [ "$1" = "exit" ]; then
  rm "$LOCKFILE"
  disown -r && exit
elif pgrep "$(basename $0)" | grep -v $$ >/dev/null; then
  echo "$(basename $0): already running"
  exit 1
else start
fi

# Check mail forever
while true; do
  # print status
  if [ $(messages-length) -gt 0 ]
  then send-command "tooltip:$USERNAME@$DOMAIN - $(messages-length) new messages - Checking..."
  else send-command "tooltip:$USERNAME@$DOMAIN - Checking..."
  fi
  # get new emails
  test-connection
  OUTPUT=()
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for LINE in $(eval "$CHECKCMD")
  do OUTPUT+=( "$LINE" )
  done
  IFS=$SAVEIFS
  # parse new emails into hash
  for ((i = 0; i < ${#OUTPUT[@]}; i = i + 2)); do
    SUBJECT="${OUTPUT[$i]}"
    ID="${OUTPUT[$i+1]}"
    if ! messages-contains "$ID"; then
      messages-set "$ID" "$SUBJECT"
      NEWMESSAGES+=( "$SUBJECT" )
    elif [ -z "$ID" ]
    then error "at least one message ID is empty" 1 # results in exit
    fi
  done
  # check for no-longer-unread messages
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for ID in $(messages-get-all); do if [ "$(contains "${OUTPUT[@]}" "$ID")" = "n" ]
  then messages-unset "$ID"
  fi; done
  IFS=$SAVEIFS
  # update tray icon
  if [ $(messages-length) -gt 0 ]
  then set-unread $(messages-length)
  else set-read
  fi
  # send notifications
  if [ "$NOTIFY" = "true" ]; then for MESSAGE in "${NEWMESSAGES[@]}"; do
    notify-send -i "$UNREADICON" -a "$(basename $0)" "$USERNAME@$DOMAIN" "$MESSAGE"
    sleep 1 # so xfce4-notifyd can keep up
  done; fi
  NEWMESSAGES=()
  poll
done
