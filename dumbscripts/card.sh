#!/bin/bash
# Swap an NVidia video card's bound driver between the host nvidia
# driver and a QEMU/KVM virtual machine's vfio-pci driver for passthru

PCI=0000:07:00.0
APCI=$(echo $PCI | sed -e "s/0$/1/")
GPU="/sys/bus/pci/devices/$PCI"
AUDIO="/sys/bus/pci/devices/$APCI"
DRIVER=amdgpu # can change to nouveau or ati or whatever
MANAGER=lightdm # can change to gdm or whatever

if xset q &>/dev/null; then
  echo "Run me again, as root, after logout ;)"
  $HOME/.dumbscripts/logout.sh
  exit
fi

systemctl stop $MANAGER

sleep 2

if [ "$1" = "vm" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/$DRIVER/unbind &
    sleep 2
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/snd_hda_intel/unbind &
    sleep 2
  fi
  echo 1 > /sys/bus/pci/devices/$PCI/remove &
  echo 1 > /sys/bus/pci/devices/$APCI/remove &
  sleep 2
  echo 1 > /sys/bus/pci/rescan &
  sleep 2
  if [ -d "$GPU" ]; then
    echo "$(<$GPU/vendor)" "$(<$GPU/device)" > /sys/bus/pci/drivers/vfio-pci/new_id &
  fi
  if [ -d "$AUDIO" ]; then
    echo "$(<$AUDIO/vendor)" "$(<$AUDIO/device)" > /sys/bus/pci/drivers/vfio-pci/new_id &
  fi
elif [ "$1" = "host" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/vfio-pci/unbind &
    sleep 2
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/vfio-pci/unbind &
    sleep 2
  fi
  echo 1 > /sys/bus/pci/devices/$PCI/remove &
  echo 1 > /sys/bus/pci/devices/$APCI/remove &
  sleep 2
  echo 1 > /sys/bus/pci/rescan &
  sleep 2
  if [ -d "$GPU" ]; then
    echo "$(<$GPU/vendor)" "$(<$GPU/device)" > /sys/bus/pci/drivers/$DRIVER/new_id &
  fi
  if [ -d "$AUDIO" ]; then
    echo "$(<$AUDIO/vendor)" "$(<$AUDIO/device)" > /sys/bus/pci/drivers/snd_hda_intel/new_id &
  fi
else
  echo "Provide an option: host or vm (virtual machine)"
  exit
fi

sleep 3

systemctl start $MANAGER
