#!/bin/bash
# wait for internet connection to make decisions about quodlibet
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER)
#NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has (not important here)

while ! nc -zw1 google.com 80; do sleep 1; done

if ! nc -zw1 $(sed -n 1p $INFO/$ROUTER.info) 22
then for ((i=0; i<$(sed -n 2p $INFO/ROUTER); i+=1)); do
    if nc -zw1 10.42.$i.1 22
    then
      touch $HOME/.dumbscripts/quodlibet-found-router
      break
    fi
  done
  else touch $HOME/.dumbscripts/quodlibet-found-router
fi

sleep 1

if [ -f $HOME/.dumbscripts/quodlibet-found-router ]
  then rm $HOME/.dumbscripts/quodlibet-found-router
  else $HOME/.dumbscripts/quodlibet.sh &
fi
