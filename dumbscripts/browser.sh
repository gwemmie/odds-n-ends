#!/bin/bash

# My default browser script. This script does a number of things:
# 1. Parses links to get rid of URL redirects, automatically convert
# HTML character codes (like http%2A%3F%3F turns into http://), and open
# known files in your program of choice using a Bash 4 hash
# 2. Automatically opens all links on ONE computer in the network, the
# designated "ROUTER". So, if you click a link from your laptop and your
# default browser is set to this script, it'll open that link in your
# "ROUTER", or in my case, my desktop, according to what you've set in
# the files it draws all that info from. As a bonus, it's smart enough
# to open the link in that laptop if the "ROUTER" is not accessible, or
# if it doesn't have a Logitech mouse plugged in. That's great for if
# you have a KVM switch and don't want to open links in a desktop whose
# mouse & keyboard are currently plugged into another computer.

# NOTE: Unlike other dumbscripts, this one assumes it lives in
# $HOME/.mydefaults instead of .dumbscripts, to be consistent with the
# freedesktop standards of your default browser being in .mydefaults. I
# just created a symlink:
# $HOME/.mydefaults/browser.sh -> ../.dumbscripts/browser.sh
# Or you could just keep it in .mydefaults. That's fine, too.

# But, Jimi, why make this whole thing when KDE already has these
# features?
# Because I like XFCE better than KDE, and KDE was super super buggy
# about deciding when to open links in other programs anyway. Or at
# least KDE 4 was. Like there was NO way to automatically open HTML
# files in a text editor while also opening an image file in your image
# viewer. You had to pick one of those. Por qué no los dos?

BROWSER=/usr/bin/firefox
INFO=$HOME/Dropbox/Settings/Scripts
ROUTERUSER=jimi # your username
ROUTER=$(sed -n 1p $INFO/$(sed -n 1p $INFO/ROUTER).info) # hostname of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has
OPS="-i $HOME/.ssh/id_rsa_Death-Tower -o StrictHostKeyChecking=no" # SSH options
CMD="DISPLAY=:0 $HOME/.mydefaults/browser.sh $1 &"
LINK="$(echo -e $(echo $1 | sed 's/%/\\x/g') | sed 's|http.*://l.facebook.com/l.php?u=||' | sed 's|http.*://www.google.com/url?q=||' | sed 's|http.*://steamcommunity.com/linkfilter/?url=||')"
RETURN=.mydefaults/browser-return
AUDIO=/usr/bin/mplayer
VIDEO=/usr/bin/smplayer
IMAGE=/usr/bin/ristretto
declare -A MEDIA=([".mp3"]=$AUDIO [".m4a"]=$AUDIO [".ogg"]=$AUDIO \
                  [".wav"]=$AUDIO [".flac"]=$AUDIO [".aac"]=$AUDIO \
                  [".alac"]=$VIDEO [".webm"]=$VIDEO [".mp4"]=$VIDEO \
                  [".mkv"]=$VIDEO [".flv"]=$VIDEO [".avi"]=$VIDEO \
                  [".jpg"]=$IMAGE [".jpeg"]=$IMAGE [".png"]=$IMAGE \
                  [".gif"]=$IMAGE)

# Check if string contains a defined media extension after its last /
function MEDIA-contains() {
  for i in "${!MEDIA[@]}"; do
    if echo "$1" | cut -d'/' -s -f1- --output-delimiter=$'\n' | tail -1 | grep -qi "$i"; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

# Link-opening logic
function open-link() {
  local CMD="\"$LINK\""
  local EXT=$(MEDIA-contains "$LINK")
  if [ "$EXT" = "" ]; then
    $CMD="$BROWSER $CMD"
  else
    CMD="${MEDIA[$EXT]} $CMD"
  fi
  if [ "$1" = "return" ]; then
    CMD="/usr/bin/ssh $OPS $(sed -n 1p $INFO/$(cat $RETURN).info) DISPLAY=:0 $CMD"
  fi
  eval "$CMD" &
}

# Routing logic & actual execution
if [ $(hostname) = "$(sed -n 1p $INFO/ROUTER)" ]; then
  if [[ $(lsusb | grep Logitech) =~ "Mouse" ]]; then
    open-link
  else
    open-link return
  fi
  rm $HOME/$RETURN || true
else
  echo $(hostname) > $HOME/$RETURN
  if nc -zw1 $ROUTER 22; then
    scp $OPS $RETURN $ROUTERUSER@$ROUTER:/home/$ROUTERUSER/.mydefaults
    ssh $OPS $ROUTERUSER@$ROUTER $CMD
  else
    touch $HOME/.mydefaults/browser-gotit
    for ((i=0; i<$NATS; i+=1))
    do
      if nc -zw1 10.42.$i.1 22; then
        scp $OPS $RETURN $ROUTERUSER@10.42.$i.1:/home/$ROUTERUSER/.mydefaults
        ssh $OPS $ROUTERUSER@10.42.$i.1 $CMD
        rm $HOME/.mydefaults/browser-gotit || true
        break
      fi
    done
  fi
  if [ -f $HOME/.mydefaults/browser-gotit ]; then
    rm $HOME/.mydefaults/browser-gotit || true
    open-link
  fi
  rm $HOME/$RETURN || true
fi
