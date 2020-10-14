#!/bin/bash
# Wrapper for unison that does a bunch of stuff I need. This one is too specific to me to be anything more than a template.
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has
PI="moon"
ARGS=1
GUI="false"
if [ "$1" = "windows" ] || [ "$1" = "clear" ] || [ "$1" = "mount-local" ] \
|| [ "$1" = "umount-local" ] || [ "$1" = "clear-local" ]; then
  ARGS=2
  if [ "$2" = "--gui" ]; then
    GUI="true"
    ARGS=3
  fi
elif [ "$1" = "--gui" ]; then
  GUI="true"
  ARGS=2
fi
if $HOME/.findpi.sh 1>/dev/null
then BACKUPIP=$($HOME/.findpi.sh)
else
  if [ "$GUI" = "true" ]
  then notify-send -u critical -t 300000 "$(basename $0): WARNING: could not find pi"
  else echo "WARNING: could not find pi"
  fi
fi
BACKUPDIR="/media/Backup"
BACKUPDIRROOT="$BACKUPDIR/$USER"
VM=.local/libvirt/images
REPLACE_WINDOWS=false
IGNORES=( currentsteam localonly tempfiles ) # ~/.unison/ scripts with ignores that we don't want stored in the cloud--remember to NEVER include cloudonly--that will delete those cloud-only files from the cloud!
CLOUDONLY="$HOME/.unison/cloudonly"

# set unison profiles to match current device IPs
# deprecated and currently causes currentsteam to be empty unless I move the currentsteam block above this code block in this file (super weird, I know)
#SAVEIFS=$IFS
#IFS=$(echo -en "\n\b")
#for i in $(ls $INFO)
#do
#  if [[ "$i" =~ "$ROUTER" ]] || [ "$i" = "ROUTER" ]; then
#    continue
#  fi
#  i=$(echo $i | sed 's/.info//')
#  sed -i "s|ssh://.*//|ssh://$(sed -n 1p $INFO/$i.info)//|" $HOME/.unison/$i.prf
#  if [ "$i" = "$(hostname)" ]; then
#    for ((j=0; j<$NATS; j+=1))
#    do
#      if [[ "$(sed -n 1p $INFO/$i.info)" =~ "10.42.$j" ]]; then
#        sed -i "s|ssh://.*//|ssh://10.42.$j.1//|" $HOME/.unison/$ROUTER.prf
#        break
#      fi
#    done
#  fi
#done
#IFS=$SAFEIFS

# set current steam games
SHAREDCONFIG="$HOME/.local/share/Steam/userdata/14588352/7/remote/sharedconfig.vdf"
CURRENTSTEAM="$HOME/.unison/currentsteam"
echo > "$CURRENTSTEAM"
for i in $(grep -i -B10 current "$SHAREDCONFIG" 2>/dev/null \
| grep -B4 tags | grep -E '"[0-9]+"' | grep -Ev '[A-Za-z]' | sed 's/\s*"//g'); do
  INSTALLDIR="$(grep -i installdir $HOME/.local/share/Steam/SteamApps/appmanifest_$i.acf 2>/dev/null | sed 's/\s*"installdir"\s*//' | sed 's/^"//' | sed 's/"$//')"
  if ! [ -z "$INSTALLDIR" ]; then
    echo "ignorenot=BelowPath .local/share/Steam/SteamApps/common/$INSTALLDIR" >> "$CURRENTSTEAM"
    echo "ignorenot=BelowPath .local/share/Steam/SteamApps/compatdata/$i" >> "$CURRENTSTEAM"
  fi
done

if [ "$1" = "windows" ] && [ $(hostname) = "Death-Tower" ]; then
  # umount windows
  if [ -d "$HOME/$VM/windows-games" ]; then
    sudo umount "$HOME/$VM/windows-games" 2>/dev/null
    rmdir "$HOME/$VM/windows-games" 2>/dev/null
  fi
  if $HOME/.sshpi.sh [ -d "$BACKUPDIR/$USER/$VM/windows-games" ]; then
    gkeyring -name "$PI" --keyring login -o secret | $HOME/.sshpi.sh sudo -S umount "$BACKUPDIR/$USER/$VM/windows-games" 2>/dev/null
    $HOME/.sshpi.sh rmdir "$BACKUPDIR/$USER/$VM/windows-games" 2>/dev/null
  fi
  # mount windows
  mkdir "$HOME/$VM/windows-games"
  $HOME/.sshpi.sh mkdir "$BACKUPDIR/$USER/$VM/windows-games"
  sudo mount -o uid=1000,gid=1000,offset=1048576,rw "$HOME/$VM/windows-games.img" "$HOME/$VM/windows-games"
  ERROR1=$?
  gkeyring -name "$PI" --keyring login -o secret | $HOME/.sshpi.sh sudo -S mount -o uid=1000,gid=1000,offset=1048576,rw "$BACKUPDIR/$USER/$VM/windows-games.img" "$BACKUPDIR/$USER/$VM/windows-games"
  ERROR2=$?
  if [ "$ERROR1" != 0 ] || [ "$ERROR2" != 0 ]; then
    echo "WARNING: could not mount windows"
    notify-send -u critical -t 300000 "$(basename $0): WARNING: could not mount windows"
  fi
fi

function local-ops() {
  if [ "$1" = "mount-local" ]
  then echo "mounting cloud-only remote folders..."
  elif [ "$1" = "umount-local" ]; then
    echo "unmounting cloud-only remote folders..."
    ERROR=0
    for MOUNTPOINT in $(IFS=$(echo -en "\n\b") mount -v | grep $PI | awk '{print $3}'); do
      umount "$MOUNTPOINT"
      TEMPERROR=$?
      if [ "$ERROR" = "0" ]
      then ERROR=$TEMPERROR
      fi
    done
    return $ERROR
  else echo "clearing cloud-only files from local machine..."
  fi
  # parse unison ignores
  IGNORENOT="/tmp/unison-script-ignorenot"
  IGNORED="/tmp/unison-script-ignored"
  SCRIPT="/tmp/unison-script.sh"
  echo | tee "$IGNORENOT" "$IGNORED"
  echo '#!/bin/bash' > "$SCRIPT"
  echo 'set -x' >> "$SCRIPT"
  while read LINE; do
    LINE="$(echo "$LINE" | sed 's/\#.*//')"
    if [[ "$LINE" =~ "ignorenot=Path" ]] || [[ "$LINE" =~ "ignorenot=BelowPath" ]]; then
      EDITEDLINE="$(echo "$LINE" | sed 's/ignorenot=BelowPath //' | sed 's/ignorenot=Path //' | sed 's/\s*$//' | sed 's/"/\\\\"/g')"
      if ! grep -Fq "\"$EDITEDLINE$\"" "$IGNORENOT"; then
        if [[ "$EDITEDLINE" =~ "*" ]]
        then printf "\"$HOME/%s\"\n" $EDITEDLINE >> "$IGNORENOT"
        else printf "\"%s\"\n" "$HOME/$EDITEDLINE" >> "$IGNORENOT"
        fi
      fi
    elif [[ "$LINE" =~ "ignore=Path" ]] || [[ "$LINE" =~ "ignore=BelowPath" ]]; then
      EDITEDLINE="$(echo "$LINE" | sed 's/ignore=BelowPath //' | sed 's/ignore=Path //' | sed 's/\s*$//' | sed 's/"/\\\\"/g')"
      if ! grep -Fq "\"$EDITEDLINE$\"" "$IGNORED"; then
        if [[ "$EDITEDLINE" =~ "*" ]]
        then printf "\"$HOME/%s\"\n" $EDITEDLINE >> "$IGNORED"
        else printf "\"%s\"\n" "$HOME/$EDITEDLINE" >> "$IGNORED"
        fi
      fi
    fi
  done < "$CLOUDONLY"
  # remove ignorenots from deletion list
  while read LINE; do
    if ! [ -z "$LINE" ]
    then sed -i "s|\s*$LINE||g" "$IGNORED"
    fi
  done < "$IGNORENOT"
  # make script
  while read LINE; do
    if ! [ -z "$LINE" ]; then
      if [ "$1" = "mount-local" ]; then
        if ! mount -v | grep moon | grep -q "$(echo $LINE | sed 's/^"//' | sed 's/"$//')"; then
          LOCALDIR=$LINE
          REMOTEDIR=$(echo $LOCALDIR | sed "s|^\"$HOME/|\"$BACKUPDIRROOT/|")
          echo "mkdir -p $LOCALDIR 2>/dev/null" >> "$SCRIPT"
          echo "echo $REMOTEDIR > $LOCALDIR/cloud-only-folder" >> "$SCRIPT"
          echo "sshfs -o allow_other,default_permissions,kernel_cache,auto_cache,cache=yes,compression=no,reconnect $PI:$REMOTEDIR $LOCALDIR" >> "$SCRIPT"
        fi
      else echo "rm -rf $LINE" >> "$SCRIPT"
      fi
    fi
  done < "$IGNORED"
  # run script
  chmod +x "$SCRIPT"
  if [ "$1" = "mount-local" ]; then
    if ! pgrep 'keepawake.sh' >/dev/null
    then $HOME/.dumbscripts/keepawake.sh & disown
    fi
    bash "$SCRIPT"
    return $?
  else
    sudo "$SCRIPT"
    return $?
  fi
}
if [ "$1" = "clear" ]; then
  echo "clearing ignored files from backup..."
  # parse unison ignores
  IGNORENOT="/tmp/unison-script-ignorenot"
  IGNORED="/tmp/unison-script-ignored"
  IGNOREFIND="/tmp/unison-script-ignorefind"
  SCRIPT="/tmp/unison-script.sh"
  echo | tee "$IGNORENOT" "$IGNORED" "$IGNOREFIND"
  echo '#!/bin/bash' > "$SCRIPT"
  echo 'set -x' >> "$SCRIPT"
  for FILE in ${IGNORES[@]}; do
    while read LINE; do
      LINE="$(echo "$LINE" | sed 's/\#.*//')"
      if [[ "$LINE" =~ "ignorenot=Path" ]] || [[ "$LINE" =~ "ignorenot=BelowPath" ]]; then
        EDITEDLINE="$(echo "$LINE" | sed 's/ignorenot=BelowPath //' | sed 's/ignorenot=Path //' | sed 's/\s*$//' | sed 's/"/\\\\"/g')"
        if ! grep -Fq "\"$EDITEDLINE$\"" "$IGNORENOT"; then
          if [[ "$EDITEDLINE" =~ "*" ]]
          then $HOME/.sshpi.sh -n cd "$BACKUPDIRROOT" ; printf "\"$BACKUPDIRROOT/%s\"\n" $EDITEDLINE >> "$IGNORENOT"
          else printf "\"%s\"\n" "$BACKUPDIRROOT/$EDITEDLINE" >> "$IGNORENOT"
          fi
        fi
      elif [[ "$LINE" =~ "ignore=Path" ]] || [[ "$LINE" =~ "ignore=BelowPath" ]]; then
        EDITEDLINE="$(echo "$LINE" | sed 's/ignore=BelowPath //' | sed 's/ignore=Path //' | sed 's/\s*$//' | sed 's/"/\\\\"/g')"
        if ! grep -Fq "\"$EDITEDLINE$\"" "$IGNORED"; then
          if [[ "$EDITEDLINE" =~ "*" ]]
          then $HOME/.sshpi.sh -n cd "$BACKUPDIRROOT" ; printf "\"$BACKUPDIRROOT/%s\"\n" $EDITEDLINE >> "$IGNORED"
          else printf "\"%s\"\n" "$BACKUPDIRROOT/$EDITEDLINE" >> "$IGNORED"
          fi
        fi
      elif [[ "$LINE" =~ "ignore=Name" ]]; then
        EDITEDLINE="$(echo "$LINE" | sed 's/ignore=Name //' | sed 's/\s*$//' | sed 's/"/\\\\"/g')"
        if ! grep -Fq "\"$EDITEDLINE$\"" "$IGNOREFIND"
        then printf "\"%s\"\n" "$EDITEDLINE" >> "$IGNOREFIND"
        fi
      fi
    done < $HOME/.unison/$FILE
  done
  # remove ignorenots from deletion list
  while read LINE; do
    if ! [ -z "$LINE" ]
    then sed -i "s|\s*$LINE||g" "$IGNORED"
    fi
  done < "$IGNORENOT"
  # make script
  while read LINE; do
    if ! [ -z "$LINE" ]
    then echo "rm -rf $LINE" >> "$SCRIPT"
    fi
  done < "$IGNORED"
  while read LINE; do
    if ! [ -z "$LINE" ]; then
      IGNORENOTCHECKS=""
      while read IGNORENOTLINE; do
        if ! [ -z "$IGNORENOTLINE" ] && echo $IGNORENOTLINE | grep -Eq "$(echo $LINE | sed 's/^"//' | sed 's/"$//' | sed 's/\*/.*/g')"
        # the second find -exec command will only run if the first one returns successfully,
        # making it the exact if check we need
        then IGNORENOTCHECKS+="-exec bash -c '! [[ \"{}\" =~ $IGNORENOTLINE ]]' \; "
        fi
      done < "$IGNORENOT"
      echo "find \"$BACKUPDIRROOT\" -name $LINE $IGNORENOTCHECKS -exec rm -rf \"{}\" \;" >> "$SCRIPT"
    fi
  done < "$IGNOREFIND"
  # upload & run script
  $HOME/.scppi.sh send "$SCRIPT" /tmp/
  $HOME/.sshpi.sh chmod +x "/tmp/$(basename $SCRIPT)"
  gkeyring -name "$PI" --keyring login -o secret | $HOME/.sshpi.sh sudo -S "/tmp/$(basename $SCRIPT)"
  exit $?
elif [ "$1" = "mount-local" ] || [ "$1" = "umount-local" ] || [ "$1" = "clear-local" ]; then
  local-ops "$1"
  exit $?
fi

# for now, unison isn't smart enough to avoid scanning the cloud folders
ERROR1=0
ERROR2=0
MOUNTED="false"
if mount -v | grep $PI; then
  MOUNTED="true"
  if ! local-ops "umount-local"; then
    ERROR1=$?
    if [ "$GUI" = "true" ]
    then notify-send -u critical -t 300000 "$(basename $0): ERROR: could not unmount cloud-only remote folders"
    else echo "ERROR: could not unmount cloud-only remote folders"
    fi
    exit $ERROR1
  fi
fi

#if ! pgrep 'chkbit-home' >/dev/null
#then chkbit-home >/dev/null & disown
#fi

if [ "$GUI" = "true" ]
then /usr/bin/unison-gtk2 ${@:$ARGS} & wait $!
else
  /usr/bin/unison-text ${@:$ARGS}
  ERROR1=$?
fi

#if ! pgrep 'chkbit-remote' >/dev/null
#then chkbit-remote "$BACKUPDIRROOT" >/dev/null & disown
#fi

if [ "$MOUNTED" = "true" ]; then
  local-ops "mount-local"
  ERROR2=$?
fi

if [ "$ERROR1" != 0 ]
then exit $ERROR1
else
  (gkeyring -name "$PI" --keyring login -o secret; hostname) | $HOME/.sshpi.sh sudo -S sh -c "tail -1 > $BACKUPDIR/mode"
  exit $ERROR2
fi
