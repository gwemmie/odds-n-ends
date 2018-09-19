#!/bin/bash
# Now that I've learned about yad, I have a feeling I'm going to be scripting a lot of my
# own tray icons. To make that easier to manage, this script automatically daemonizes them
# so that I don't have to manually restart (and keep track of) an icon after it fails or
# gets turned off.
# To make any yad-using tray icon script compatible, take these steps:
# - end its name in .sh (or modify this script to not require that)
# - make sure the first occurrence of "ICON=" in the script is in the format .*ICON="<icon name>".*
#   and is the icon that script's tray icon normally uses
# - save whatever icon you want to be the script's "error" icon as
#   $HOME/.local/share/icons/<script's normal icon name>-x.<any extension compatible with systray>
#   Example: for mail-notify.sh, my normal icon is "gmail-offline", so I modified that to have
#     an X emblem on it, and saved that as $HOME/.local/share/icons/gmail-offline-x.svg
LOCATION="$HOME/.dumbscripts" # where scripts live
SCRIPTS=( mail-notify )
declare -A YADPIDS

if ! hash yad 2>/dev/null; then
  echo "ERROR: this script requires yad"
  exit 1
fi

while true; do
  for SCRIPT in "${SCRIPTS[@]}"; do if ! pgrep "$SCRIPT.sh"; then
    if ! [ ${YADPIDS["$SCRIPT"]+_} ]; then
      ICON="$(grep "ICON=" "$LOCATION/$SCRIPT.sh" | head -1 | sed 's/.*ICON="//' | sed 's/".*//')-x"
      yad --notification --text="$SCRIPT is broken, click to restart" --command="$LOCATION/$SCRIPT.sh" --image="$ICON" 2>/dev/null &
      YADPIDS["$SCRIPT"]=$!
    elif ! ps ${YADPIDS["$SCRIPT"]}
    then unset YADPIDS["$SCRIPT"]
    fi
  elif [ ${YADPIDS["$SCRIPT"]+_} ]; then
    kill ${YADPIDS["$SCRIPT"]}
    unset YADPIDS["$SCRIPT"]
  fi; done
  sleep 1
done
