#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
PKG=$BACKUP/pkg/$(hostname)
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
ROUTERIP=$(sed -n 1p $INFO/$ROUTER.info) # IP of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has
UPGRADE_STEAM=false

# packages we don't want the package manager to update (at least not automatically)
SPLITP=( linux-rt-lts-docs linux-rt-lts-headers citra-qt-git libc++abi libc++experimental )
MANUAL=( zyn-fusion qjackctl )
BADVER=( xfce4-sensors-plugin )
IGNORE="${SPLITP[@]/#/--ignore } ${MANUAL[@]/#/--ignore } ${BADVER[@]/#/--ignore }"

cache-upgrade() {
  FILE="$(ls /var/cache/pacman/pkg/$1* | grep -P "$1-([0-9]|r[0-9]|latest)" | tail -1)"
  # can't have this function universally fail to upgrade a package named downgrade
  if [[ "$FILE" =~ "downgrad" ]] \
  || ! [[ "$(echo -e "n\n" | sudo pacman -U $FILE 2>&1)" =~ "downgrad" ]]
  then sudo pacman -U --noconfirm --needed $FILE
  fi
}

while true; do
  read -n 1 -p "Skip kernel upgrade to avoid reboot? [Y/n] " ANS
  case $ANS in
    [Nn] ) echo; break;;
       * ) echo; IGNORE="$IGNORE --ignore linux --ignore linux-lts"; break;;
  esac
done

# preliminary stuff
if ! [ -f $HOME/.updated ] || test "`find $HOME/.updated -mtime +1`"; then
  UPGRADE_STEAM=true
  # update mirror
  sudo echo # to get the password prompt out of the way
  echo -n "Updating mirrorlist... "
  sudo reflector --country 'United States' -l 200 --sort rate --save /etc/pacman.d/mirrorlist
  echo $?
  # copy already-updated cache
  if [ "$(hostname)" != "$ROUTER" ]; then
    echo "Copying cache from $ROUTER..."
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for i in $(ls $BACKUP/pkg/$ROUTER/*.tar.xz)
    do sudo cp "$i" /var/cache/pacman/pkg/
    done
    IFS=$SAVEIFS
  fi
  touch $HOME/.updated
fi

# update packages
echo "Upgrading manual packages:"
echo ${MANUAL[@]}
for pkg in ${MANUAL[@]}
do cache-upgrade $pkg
done
echo "AUR packages to upgrade:"
echo n | eval "yaourt -Su --aur $IGNORE" 2>/dev/null | grep "aur/" | perl -0777 -pe 's/.*\r//g' | sed 's|aur/||'
echo "Official packages to upgrade:"
eval "yaourt -Syu $IGNORE"
echo "Upgrading AUR..."
for i in $(echo n | eval "yaourt -Su --aur $IGNORE" 2>/dev/null | grep "aur/" | perl -0777 -pe 's/.*\r//g' | sed 's|aur/||')
do cache-upgrade $i
done
eval "yaourt -Su --aur --noconfirm $IGNORE"

# unwanted files from certain package upgrades
if [ -f $HOME/.config/autostart/dropbox.desktop ]; then
  sudo rm $HOME/.config/autostart/dropbox.desktop
fi
rmdir $HOME/Unity-*

$HOME/.upgrade-cache.sh

$HOME/.upgrade-git.sh

if [ "$UPGRADE_STEAM" = "true" ]
then $HOME/.upgrade-steam.sh
fi
