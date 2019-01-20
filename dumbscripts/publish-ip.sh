#!/bin/bash
# publish IPs to Dropbox
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
EXIP=$(sed -n 2p $INFO/$ROUTER.info) # public IP on last boot
/usr/bin/ifconfig $(ip route ls | grep 'default via' | head -1 | awk '{ print $5}') | grep 'inet ' | awk '{ print $2}' > $INFO/$(hostname).info

if [ $(hostname) = "Death-Tower" ]; then
  NEWEXIP=$(/usr/bin/dig +short myip.opendns.com @resolver1.opendns.com)
  if [ "$EXIP" != "$NEWEXIP" ]
  then notify-send -u critical -t 300000 "public IP has changed from $EXIP to $NEWEXIP"
  fi
  echo $NEWEXIP >> $INFO/$(hostname).info
fi
