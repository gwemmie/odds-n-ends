#!/bin/bash
# update gits
DIR="$(pwd)"
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
    if [ "$i" = "steam-rom-manager" ]
    then rm package-lock.json
    fi
    git pull
    if [ "$i" = "punk" ] \
    || [ "$i" = "steam-rom-manager" ]; then
      if ! hash npm 2>/dev/null; then
        yaourt -S --asdeps npm
        NEEDED="yes"
      fi
      npm install
      if [ "$i" = "punk" ]; then
        npm run build
        npm run watch
      elif [ "$i" = "steam-rom-manager" ]; then
        npm run build:dist
      fi
      if [ "$NEEDED" = "yes" ]; then yaourt -Rns npm; fi
    elif [ "$i" = "texttop" ]; then
      if ! hash docker 2>/dev/null; then
        yaourt -S --asdeps docker
        sudo systemctl start docker
        NEEDED="yes"
      fi
      sudo docker build -t texttop ./
      if [ "$NEEDED" = "yes" ]; then
        sudo systemctl stop docker
        yaourt -Rns docker
      fi
    fi
    if [ "$i" = "Cataclysm-DDA" ]; then
      if ! hash lua5.1 2>/dev/null; then
        yaourt -S --asdeps lua51
        NEEDED="yes"
      fi
      make -j4 CCACHE=1
      if [ "$NEEDED" = "yes" ]; then yaourt -Rns lua51; fi
    fi
  elif [ $REMOTE = $BASE ]; then
    echo -n "Need to push"
    if [ "$i" != "odds-n-ends" ]; then
      echo " but not our repo"
      cd ..
      continue
    else echo
    fi
    git push
  else
    echo "Diverged"
  fi

  cd ..
done
IFS=$SAVEIFS
cd "$DIR"
