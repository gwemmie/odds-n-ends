#!/bin/bash
# Disable screensaver & all that extra jazz.
# Use this if you just want your screen to be on all the time until you
# TELL it to turn off.

# I've found I need this script to run every 30 seconds as it does when
# I'm on the NVidia drivers, but not on nouveau. I suppose open-source
# drivers are better about respecting Linux users and their control over
# their computers. You may or may not need the while loop and sleep 30.

while true; do
  xset s 0 0
  xset s off
  xset -dpms
  sleep 30
done
