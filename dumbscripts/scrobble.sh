#!/bin/bash

# Scrobbles songs according to a newline-separated list of filenames
# (like an M3U playlist) and a starting time (or now if not specified)
# I made this because iPhones are pieces of shit and I was forced to
# switch to a music-playing situation that can't scrobble.

# USAGE: scrobble.sh [[%Y-%m-%d.%H:%M]] <[file containing list of MP3s]

# Change this to your own username after logging in with `scrobbler add-user <user>`
USER=Jimi_James

ERROR=0
if ! hash scrobbler 2>/dev/null; then
	echo "This script requires scrobbler"
	ERROR=1
fi
# Why use mp3info AND operon? mp3info is the only easy way to get the duration,
# and yet gets screwy with Asian song titles
if ! hash operon 2>/dev/null; then
	if [ "$ERROR" != "0" ]
	then echo -n ", "
	else echo -n "This script requires "
	fi
	echo "operon"
	ERROR=1
fi
if ! hash mp3info 2>/dev/null; then
	if [ "$ERROR" != "0" ]
	then echo -n ", "
	else echo -n "This script requires "
	fi
	echo "mp3utils"
	ERROR=1
fi
if ! hash dateconv 2>/dev/null; then
	if [ "$ERROR" != "0" ]
	then echo -n ", "
	else echo -n "This script requires "
	fi
	echo "dateutils"
	ERROR=1
fi
# You can probably use dc instead just fine, but dc is acting super weird
# on my computer and I don't care enough to fix it because bc is better,
# so I left this warning
if ! hash bc 2>/dev/null; then
	if [ "$ERROR" != "0" ]
	then echo -n ", and "
	else echo -n "This script requires "
	fi
	echo "bc"
	ERROR=1
fi
if [ "$ERROR" != "0" ]
then exit 1
fi

# check for arg 1 and default to current time if no arg 1
# plagiarized from https://superuser.com/questions/747884/how-to-write-a-script-that-accepts-input-from-a-file-or-from-stdin
[ $# -ge 1 ] && TIME="$1" || TIME="$(date +'%Y-%m-%d.%H:%M')"

echo "Scrobbling tracks..."
while read -r LINE
do
	echo "$LINE"
	if [[ "$(mp3info "$LINE")" =~ "does not have an ID3" ]] \
	|| [[ "$(mp3info "$LINE")" =~ "No MP3 files specified" ]]
	then continue
	fi
	DURATION=$(mp3info -p "%mm%ss" "$LINE")
	# do some math around the duration because mp3info doesn't support outputting hours
	HOURS="0"
	MINUTES=$(echo "$DURATION" | sed 's/[0-9]*s//')
	SECONDS=$(echo "$DURATION" | sed 's/[0-9]*m//')
	MINUTESNUM=$(echo $MINUTES | sed 's/m//')
	if [ $MINUTESNUM -ge 60 ]; then
		HOURS=$(bc <<< "$MINUTESNUM / 60")
		MINUTESNUM=$(expr $MINUTESNUM - $(bc <<< "60 * $HOURS"))
		MINUTES=$MINUTESNUM
		MINUTES+="m"
	fi
	HOURS+="h"
	DURATION="${HOURS}${MINUTES}${SECONDS}"
	ALBUM=$(operon print -p '<album>' "$LINE")
	ARTIST=$(operon print -p '<artist>' "$LINE")
	TITLE=$(operon print -p '<title>' "$LINE")
	scrobbler scrobble -a "$ALBUM" -d "$DURATION" "$USER" "$ARTIST" "$TITLE" "$TIME"
	echo "Scrobbled at $TIME"
	# increase TIME by DURATION
	if [ $(echo $SECONDS | sed 's/m//') -ge 30 ]; then
		let MINUTESNUM+=1 # rounding up the seconds
		MINUTES=$MINUTESNUM
		MINUTES+="m"
	fi
	TIME="$(dateadd -i '%Y-%m-%d.%H:%M' -f '%Y-%m-%d.%H:%M' "$TIME" +"$DURATION")"
	sleep 5 # or else you get "Exceeded the limit of one request per five seconds over five minutes."
done
