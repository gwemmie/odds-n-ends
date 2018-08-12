#!/bin/bash
# Runs unison after changing my profiles to match the IPs of my multiple
# computers. This one is too specific to me to be anything more than a
# template.
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
NATS=$(sed -n 2p $INFO/ROUTER) # number of NAT networks router has

# set unison profiles to IPs
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for i in $(ls $INFO)
do
  if [[ "$i" =~ "$ROUTER" ]] || [ "$i" = "ROUTER" ]; then
    continue
  fi
  i=$(echo $i | sed 's/.info//')
  sed -i "s|ssh://.*//|ssh://$(sed -n 1p $INFO/$i.info)//|" $HOME/.unison/$i.prf
  if [ "$i" = "$(hostname)" ]; then
    for ((j=0; j<$NATS; j+=1))
    do
      if [[ "$(sed -n 1p $INFO/$i.info)" =~ "10.42.$j" ]]; then
        sed -i "s|ssh://.*//|ssh://10.42.$j.1//|" $HOME/.unison/$ROUTER.prf
        break
      fi
    done
  fi
done
IFS=$SAFEIFS

/usr/bin/unison-gtk2 & disown
