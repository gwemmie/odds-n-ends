#!/bin/bash
# UC Santa Cruz Linux students rejoice! If you provide a lynx script
# that types in your username & password and hits the Go button, you'll
# never have to login to SafeConnect again. That means storing your
# password in plain text on your hard drive, though.

# This is not a usual method of checking for broken internet. This is
# the only one that works with SafeConnect

while true; do
  ping -c 1 www.facebook.com 1>/dev/null 2>/dev/null  # Can't be Google,
            # because Google can still be pinged when SafeConnect blocks
  if [ "$?" = 1 ]; then  # ping returns 1 for packet loss when
                         # SafeConnect blocks
    chmod +r $HOME/.dumbscripts/lynx-safeconnect
    # SafeConnect only works with a well-known UserAgent
    lynx -useragent='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.0' -accept-all-cookies -cmd_script=$HOME/.dumbscripts/lynx-safeconnect http://198.31.193.211:8008
    chmod -r $HOME/.dumbscripts/lynx-safeconnect
  fi
  sleep 2
done
