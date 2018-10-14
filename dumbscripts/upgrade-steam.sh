#!/bin/bash
# update steam games
ls -1 $HOME/.local/share/Steam/SteamApps/ | grep appmanifest | sed -r 's/appmanifest_([0-9]+).acf/\1/' > /tmp/steam-update
sed -i 's/^/app_update /' /tmp/steam-update
sed -i '1ilogin leo_garth <password>' /tmp/steam-update
echo quit >> /tmp/steam-update
steamcmd +runscript /tmp/steam-update
rm /tmp/steam-update
