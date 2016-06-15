#!/bin/bash
# Swap an NVidia video card's bound driver between the host nvidia
# driver and a QEMU/KVM virtual machine's vfio-pci driver for passthru
# Assumes you run lightdm. Can easily be modified for ATI. Can also be
# modified for open-source drivers on the host, but mine doesn't support
# my very new card yet.

PCI=0000:06:00.0
APCI=$(echo $PCI | sed -e "s/0$/1/")
GPU="/sys/bus/pci/devices/$PCI"
AUDIO="/sys/bus/pci/devices/$APCI"
DRIVER=nvidia # can change to nouveau or ati or whatever

if xset q &>/dev/null; then
  echo "Run me again, as root, after logout ;)"
  $HOME/.dumbscripts/logout.sh
  exit
fi

systemctl stop lightdm

sleep 2

if [ "$1" = "vm" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/$DRIVER/unbind
    echo $(cat $GPU/vendor) $(cat $GPU/device) > /sys/bus/pci/drivers/vfio-pci/new_id
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/snd_hda_intel/unbind
    echo $(cat $AUDIO/vendor) $(cat $AUDIO/device) > /sys/bus/pci/drivers/vfio-pci/new_id
  fi
elif [ "$1" = "host" ]; then
  if [ -d "$GPU" ]; then
    echo $PCI > /sys/bus/pci/drivers/vfio-pci/unbind
    echo $(cat $GPU/vendor) $(cat $GPU/device) > /sys/bus/pci/drivers/$DRIVER/new_id
  fi
  if [ -d "$AUDIO" ]; then
    echo $APCI > /sys/bus/pci/drivers/vfio-pci/unbind
    echo $(cat $AUDIO/vendor) $(cat $AUDIO/device) > /sys/bus/pci/drivers/snd_hda_intel/new_id
  fi
else
  echo "Provide an option: host or vm (virtual machine)"
  exit
fi

sleep 3

systemctl start lightdm
