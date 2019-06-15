#!/bin/bash
# publish IPs to Dropbox
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
EXIP=$(sed -n 2p $INFO/$ROUTER.info) # public IP on last boot
if ! [ -e "$INFO/$(hostname).info" ]
then touch "$INFO/$(hostname).info"
fi
sed -i "1s|.*|$(/usr/bin/ifconfig $(ip route ls | grep 'default via' | head -1 | awk '{ print $5}') | grep 'inet ' | awk '{ print $2}')|" $INFO/$(hostname).info

NEWEXIP=$(/usr/bin/dig +short myip.opendns.com @resolver1.opendns.com)
if echo "$NEWEXIP" | grep -qvx "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\|[a-zA-Z0-9]\+::[a-zA-Z0-9]\+:[a-zA-Z0-9]\+:[a-zA-Z0-9]\+:[a-zA-Z0-9]\+/[0-9]\+"
then if $HOME/.dumbscripts/check-internet.sh
  then notify-send -u critical -t 300000 "could not get public IP"
  fi
elif echo "$NEWEXIP" | grep -qx "10\.0\..*\|192\.168\..*"
then if $HOME/.dumbscripts/check-internet.sh
  then notify-send -u critical -t 300000 "public IP is local"
  fi
else
  if [ "$EXIP" != "$NEWEXIP" ]
  then notify-send -u critical -t 300000 "public IP has changed from $EXIP to $NEWEXIP"
  fi
  if [ -z "$(sed -n 2p < "$INFO/$(hostname).info")" ]
  then echo "$NEWEXIP" >> $INFO/$(hostname).info
  else sed -i "2s|.*|$NEWEXIP|" $INFO/$(hostname).info
  fi
fi
