#!/bin/bash
# Resets the modem if the internet goes down. Can be modified to handle
# a router, too.
# This is way too specific to me to be anything but a template.

while true; do
  if ! $HOME/.dumbscripts/check-internet.sh; then if ! $HOME/.dumbscripts/check-internet.sh; then
    lynx -cmd_script=$HOME/.dumbscripts/lynx-modem http://192.168.100.1/cmConfig.htm
    sleep 20
    if ! nc -zw1 google.com 80; then
      notify-send -u critical -t 300000 "Need to restart router; waiting 5 minutes..."
      echo "Need to restart router; waiting 5 minutes..."
      sleep 300
    fi
  fi fi
  echo "internet working"
  sleep 2
done
