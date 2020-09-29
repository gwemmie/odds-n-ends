#!/bin/bash
# Swap a video card's bound driver between the host
# driver and a QEMU/KVM virtual machine's vfio-pci driver for passthru
set -e

PCI=0000:05:00.0
APCI=$(echo $PCI | sed -e "s/0$/1/")
GPU="/sys/bus/pci/devices/$PCI"
AUDIO="/sys/bus/pci/devices/$APCI"
DRIVER=amdgpu # can change to nouveau or ati or whatever
MANAGER=lightdm # can change to gdm or whatever

if [ "$DRIVER" = "nvidia" ] && xset q &>/dev/null; then
  echo "Run me again, as root, after logout ;)"
  notify-send "card.sh: Run me again, as root, after logout ;)"
  $HOME/.dumbscripts/logout.sh
  exit 1
fi

if [ "$DRIVER" = "nvidia" ]; then
  systemctl stop $MANAGER
  sleep 2
fi

if [ "$1" = "vm" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/$DRIVER/unbind
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/snd_hda_intel/unbind
  fi
  echo 1 > /sys/bus/pci/devices/$PCI/remove
  echo 1 > /sys/bus/pci/devices/$APCI/remove
  echo 1 > /sys/bus/pci/rescan
  if [ -d "$GPU" ]; then
    echo "$(<$GPU/vendor)" "$(<$GPU/device)" > /sys/bus/pci/drivers/vfio-pci/new_id
  fi
  if [ -d "$AUDIO" ]; then
    echo "$(<$AUDIO/vendor)" "$(<$AUDIO/device)" > /sys/bus/pci/drivers/vfio-pci/new_id
  fi
elif [ "$1" = "host" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/vfio-pci/unbind
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/vfio-pci/unbind
  fi
  echo 1 > /sys/bus/pci/devices/$PCI/remove
  echo 1 > /sys/bus/pci/devices/$APCI/remove
  echo 1 > /sys/bus/pci/rescan
  if [ -d "$GPU" ]; then
    echo "$(<$GPU/vendor)" "$(<$GPU/device)" > /sys/bus/pci/drivers/$DRIVER/new_id
  fi
  if [ -d "$AUDIO" ]; then
    echo "$(<$AUDIO/vendor)" "$(<$AUDIO/device)" > /sys/bus/pci/drivers/snd_hda_intel/new_id
  fi
else
  echo "Provide an option: host or vm (virtual machine)"
  exit 1
fi

if [ "$DRIVER" = "nvidia" ]; then
  sleep 3
  systemctl start $MANAGER
fi
