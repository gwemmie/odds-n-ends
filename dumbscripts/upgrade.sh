#!/bin/bash
# HELLO TEMPLATE. This script is EXTREMELY personalized to me. It
# upgrades... everything. Yes, everything. That's why it's still a very
# valuable template. Have fun. I use Arch Linux, so that's where it'll
# help the most.

PKG=$HOME/Backup/Computers/Linux/pkg/$(hostname)

# things I don't want the script to redo every time it's run, so I limit
# them to once a day with a .updated file
if test "`find $HOME/.updated -mtime +1`";
then

# update mirror
sudo echo -n "Updating mirrorlist... "
touch $HOME/.updated
sudo reflector --country 'United States' -l 200 --sort rate --save /etc/pacman.d/mirrorlist
echo $?

# update steam games
ls -1 $HOME/.local/share/Steam/SteamApps/ | grep appmanifest | sed -r 's/appmanifest_([0-9]+).acf/\1/' > /tmp/steam-update
sed -i 's/^/app_update /' /tmp/steam-update
sed -i '1ilogin leo_garth 1mmAdgrr' /tmp/steam-update
echo quit >> /tmp/steam-update
steamcmd +runscript /tmp/steam-update
rm /tmp/steam-update

# update other games
WINEARCH=win64 WINEPREFIX="$HOME/.local/share/wineprefixes/StarCraft II" wine "$HOME/.local/share/wineprefixes/StarCraft II/drive_c/Program Files/Battle.net/Battle.net Launcher.exe" 1>/dev/null 2>/dev/null &

fi

# update packages
yaourt -Syu --ignore firefox # I'm always careful with firefox updates
sudo chmod 777 /var/cache/pacman/pkg
PKGDEST=/var/cache/pacman/pkg pacaur --noedit -Sua
sudo chmod 775 /var/cache/pacman/pkg
sudo chown root:root /var/cache/pacman/pkg/*.tar.xz
yaourt -Qtd # uninstall build-deps no longer needed
yaourt -Sc # clear package cache of not-installed package files
yaourt -C # check .pacnew config files
echo -n "Backing cache up to home folder... "
yaourt -Qqe > $PKG/list
yaourt -Qqd > $PKG/deps
rsync -rt --delete /var/cache/pacman/pkg/ $PKG/
echo $? # just so I know how that rsync went

# update gits
cd $HOME/.local/share/git
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for i in $(ls .)
do
  cd "$i"
  echo "Updating $i..."
  git remote update

  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u})
  BASE=$(git merge-base @ @{u})

  if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
  elif [ $LOCAL = $BASE ]; then
    echo "Need to pull"
    git pull
    if [ "$i" = "punk" ]; then
      npm install
      npm run build
      npm run watch
    elif [ "$i" = "texttop" ]; then
      sudo docker build -t texttop ./
    fi
  elif [ $REMOTE = $BASE ]; then
    echo "Need to push"
    git push
  else
    echo "Diverged"
  fi

  cd ..
done
IFS=$SAVEIFS
cd
