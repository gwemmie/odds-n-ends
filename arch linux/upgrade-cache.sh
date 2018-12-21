#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
PKG=$BACKUP/pkg/$(hostname)
AUR=$BACKUP/pkg/$(hostname)-AUR
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
ROUTERIP=$(sed -n 1p $INFO/$ROUTER.info) # IP of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has

# Re-creating pacman -Sc functionality for AUR packages because it seems I'm inexplicably
# the only one in the world who cares about this enough to put it in a dang AUR helper of
# any kind.
remove-non-installed() {
  for i in $1/*; do
    if ! [[ "$(echo -e "n\n" | sudo pacman -U --confirm "$i" 2>&1)" =~ "reinstall" ]]; then
      echo "Removing $i"
      rm "$i"
    fi
  done
}
function clean-aur {
  while true; do
    echo -en "\e[38;5;112m==>\e[0m "
    read -p "Clear AUR cache, keeping only installed packages? [Y/n] " ANS
    case $ANS in
      [nN] ) break;;
         * ) remove-non-installed "$AUR"; break;;
    esac
  done
}

echo "Uninstalling leftover dependencies..."
if yay -Qqtd >/dev/null
then yay -Rcn $(yay -Qqtd)
else echo "None to uninstall"
fi
yay -Sc
clean-aur
sudo pacdiff # yup turns out yaourt -C is basically just this script from pacman-contrib
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
  for i in $BACKUP/pkg/$ROUTER/*
  do rm "$BACKUP/pkg/$(hostname)/$i" "$BACKUP/pkg/$(hostname)-AUR/$i" 2>/dev/null || true
  done
fi
