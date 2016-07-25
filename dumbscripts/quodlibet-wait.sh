#!/bin/bash
# wait for internet connection to make decisions about quodlibet
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
ROUTERIP=$(sed -n 1p $INFO/$ROUTER.info) # IP of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has

while ! nc -zw1 google.com 80; do sleep 1; done

FOUND_ROUTER="false"
if ! nc -zw1 $ROUTERIP 22
then for ((i=0; i<$NATS; i+=1)); do
    if nc -zw1 10.42.$i.1 22
    then
      FOUND_ROUTER="true"
      break
    fi
  done
else FOUND_ROUTER="true"
fi
if [ "$FOUND_ROUTER" = "false" ]
then $HOME/.dumbscripts/quodlibet.sh &
fi
