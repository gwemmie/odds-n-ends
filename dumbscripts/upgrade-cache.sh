#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
PKG=$BACKUP/pkg/$(hostname)
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
ROUTERIP=$(sed -n 1p $INFO/$ROUTER.info) # IP of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has

echo "Uninstalling leftover dependencies..."
yay -Rcn $(yay -Qqtd)
yay -Sc
pacdiff # yup turns out yaourt -C is basically just this script from pacman-contrib
echo -n "Backing cache up to home folder... "
rsync -rt --delete /var/cache/pacman/pkg/ $PKG/
echo $?
yay -Qqen > $PKG/list
yay -Qqdn > $PKG/deps
yay -Qqem > $PKG/aurlist
yay -Qqdm > $PKG/aurdeps

# eliminate redundancy
if [ "$(hostname)" != "$ROUTER" ]; then
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in $(ls "$BACKUP/pkg/$ROUTER"); do
    if [ "$i" != "list" ] && [ "$i" != "deps" ] && [ "$i" != "aurlist" ] && [ "$i" != "aurdeps" ]
    then rm "$BACKUP/pkg/$(hostname)/$i" 2>/dev/null || true
    fi
  done
  IFS=$SAVEIFS
fi
