#!/bin/bash
INFO=$HOME/Dropbox/Settings/Scripts
MOONLAN=$(sed -n 1p $INFO/moon.info)
MOONWAN=$(sed -n 2p $INFO/moon.info)

TESTS=( www.google.com www.facebook.com )
PORT=80
if ! [ -z "$1" ]
then PORT=$1
fi
TIMEOUT=1
if ! [ -z "$2" ]
then TIMEOUT=$2
fi

#if ! nc -zw$TIMEOUT $MOONWAN 80 && ! nc -zw$TIMEOUT $MOONLAN 80
#then exit $?
#fi

for URL in ${TESTS[@]}; do
  nc -zw$TIMEOUT $URL $PORT
  STATUS=$?
  if (( $STATUS != 0 ))
  then exit $STATUS
  fi
  ping -c1 -w$TIMEOUT $URL
  STATUS=$?
  if (( $STATUS != 0 ))
  then exit $STATUS
  fi
done
exit $STATUS
