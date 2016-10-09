#!/bin/bash
# publish IPs to Dropbox
INFO=$HOME/Dropbox/Settings/Scripts
/usr/bin/ifconfig $(ip route ls | grep 'default via' | head -1 | awk '{ print $5}') | grep 'inet ' | awk '{ print $2}' > $INFO/$(hostname).info
/usr/bin/dig +short myip.opendns.com @resolver1.opendns.com >> $INFO/$(hostname).info
