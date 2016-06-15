#!/bin/bash
# Get the MAC address of a given IP
# Must be run with sudo
# Might I suggest making this script read-only and adding it to visudo?

INTERFACE=$(ip route show match 0/0 | awk '{print $5}')

/usr/bin/arping -f -I $INTERFACE $1 | sed -n 2p | sed 's/.*\[\(..:..:..:..:..:..\)\].*/\1/'
