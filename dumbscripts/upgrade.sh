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
NOTNOW=( unity-editor ) # huge packages that update (and redownload) *all the time* to the point that it's just not worth it unless you're currently using that program all the time
IGNORE="${SPLITP[@]/#/--ignore } ${MANUAL[@]/#/--ignore } ${BADVER[@]/#/--ignore } ${NOTNOW[@]/#/--ignore }"

cache-upgrade() {
  PKG=$1
  if [[ "$PKG" =~ "+" ]] # quick fix for libc++
  then PKG="$(echo $PKG | sed 's/\+/\\\+/g')"
  fi
  FILE="$(ls /var/cache/pacman/pkg/$PKG* | grep -P "$PKG-([0-9]|c[0-9]|r[0-9]|v[0-9]|latest)" | tail -1)"
  # can't have this function universally fail to upgrade a package named downgrade
  if [[ "$FILE" =~ "downgrad" ]] \
  || ! [[ "$(echo -e "n\n" | sudo pacman -U $FILE 2>&1)" =~ "downgrad" ]]
  then sudo pacman -U --noconfirm --needed $FILE
  fi
}

echo "REMINDER: currently in NOTNOW: ${NOTNOW[@]}"

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
echo "Upgrading system..."
eval "yay -Syu $IGNORE"

# remove unwanted files from certain package upgrades
if [ -f $HOME/.config/autostart/dropbox.desktop ]; then
  sudo rm $HOME/.config/autostart/dropbox.desktop
fi
rmdir $HOME/Unity-* 2>&1 | grep -v 'No such file or directory'

$HOME/.upgrade-cache.sh

$HOME/.upgrade-git.sh

if [ "$UPGRADE_STEAM" = "true" ]
then $HOME/.upgrade-steam.sh
fi
