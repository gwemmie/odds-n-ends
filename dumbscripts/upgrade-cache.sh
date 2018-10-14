#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
PKG=$BACKUP/pkg/$(hostname)
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
ROUTERIP=$(sed -n 1p $INFO/$ROUTER.info) # IP of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has

yaourt -Qtd
yaourt -Sc
yaourt -C
echo -n "Backing cache up to home folder... "
rsync -rt --delete /var/cache/pacman/pkg/ $PKG/
echo $?
yaourt -Qqe | grep -v "$(yaourt -Qqm)" > $PKG/list
yaourt -Qqm > $PKG/aur
yaourt -Qqd > $PKG/deps

# eliminate redundancy
if [ "$(hostname)" != "$ROUTER" ]; then
  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")
  for i in $(ls "$BACKUP/pkg/$ROUTER"); do
    if [ "$i" != "list" ] && [ "$i" != "aur" ] && [ "$i" != "deps" ]
    then rm "$BACKUP/pkg/$(hostname)/$i" 2>/dev/null || true
    fi
  done
  IFS=$SAVEIFS
fi
