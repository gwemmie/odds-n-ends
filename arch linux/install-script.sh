#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
set -e
echo "MAKE SURE YOU'RE IN WHEEL GROUP AND CAN USE SUDO AND HAVE INTERNET"
sleep 5

echo "INSTALLING PACKAGES..."
sleep 2
set -x
sudo cp $BACKUP/pkg/$(hostname)/*libgl*.tar.xz /var/cache/pacman/pkg/
sudo pacman -Sy libgl lib32-libgl
sudo pacman -Rs gcc gcc-libs
sudo pacman -U --noconfirm $BACKUP/pkg/$(hostname)/pacaur*.tar.xz
PKGDEST=$BACKUP/pkg/$(hostname) pacaur -S --noconfirm --noedit --needed $(cat $BACKUP/pkg/$(hostname)/list)
sudo cp -n $BACKUP/pkg/$(hostname)/*.tar.xz /var/cache/pacman/pkg/

set +x
echo "SETTING UP SYSTEM..."
sleep 2
set -x
sudo cp $BACKUP/bin/local/* /usr/local/bin/
sudo cp -R $BACKUP/ufw/ufw/* /etc/ufw/
sudo cp -R $BACKUP/ufw/gufw/* /etc/gufw/
sudo systemctl enable ufw.service
sudo ufw enable
sudo systemctl enable lightdm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable ntpdate.service
sudo systemctl enable bluetooth
sudo systemctl enable udisks.service
systemctl --user enable btsync
echo HandleLidSwitch=ignore | sudo tee -a /etc/systemd/logind.conf
sudo pacman -S --noconfirm flashplugin
rm -rf $HOME/.adobe/Flash_Player/{NativeCache,AssetCache,APSPrivateData2}
sudo cp $BACKUP/conf/alsa-base.conf /etc/modprobe.d/
sudo mkdir /etc/openal
echo drivers=pulse,alsa | sudo tee -a /etc/openal/alsoft.conf
echo frequency=48000 | sudo tee -a /etc/openal/alsoft.conf
sudo cp $BACKUP/conf/snd_seq_midi.conf /etc/modules-load.d/
sudo cp $BACKUP/conf/uinput.conf /etc/modules-load.d/
sudo cp $BACKUP/conf/51-gcadapter.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo cp -R $HOME/.config /root/
sudo cp -R $HOME/.local /root/
sudo cp $BACKUP/bin/version /usr/bin/version
sudo cp $HOME/Backup/Consoles/Wii\ \&\ Gamecube/dsp_*.bin $HOME/.dolphin-emu/GC/
sudo cp $HOME/Backup/Consoles/Wii\ \&\ Gamecube/dsp_*.bin /usr/share/dolphin-emu/sys/GC/
sudo cp $BACKUP/conf/51-gcadapter.rules /etc/udev/rules.d/
sudo ln -s /usr/lib/firefox /usr/lib/mozilla
sudo cp $BACKUP/conf/10-ptrace.conf /etc/sysctl.d/
sudo cp $BACKUP/conf/60-xwiimote.conf /etc/X11/xorg.conf.d/
sudo cp $BACKUP/conf/20-custom.conf /etc/X11/xorg.conf.d/
sudo cp $BACKUP/conf/engrampa.tap /usr/lib/xfce4/thunar-archive-plugin/
if [ $(hostname) = "Death-Tower" ];
then
  sudo cpupower frequency-set -g performance
  echo "governor='performance'" | sudo tee -a /etc/default/cpupower
  sudo systemctl enable cpupower.service
  sudo systemctl enable libvirtd.service
  sudo systemctl enable virtlogd.socket
  sudo systemctl enable sshd.socket
  sudo systemctl enable x2goserver.service
  sudo systemctl enable smbd.socket
  sudo cp $BACKUP/conf/panelfix.service /etc/systemd/system/
  sudo systemctl enable panelfix.service
  sudo sed -i 's/my $lines=`ss -lxu`;/my $lines=`ss -lx`;/' /usr/bin/x2golistdesktops
  sudo cp $BACKUP/conf/20-gaming-proprietary.conf /etc/X11/xorg.conf.d/
  sudo cp $BACKUP/conf/vfio-pci.conf /etc/modprobe.d/
  sudo cp $BACKUP/conf/qemu.conf /etc/libvirt/
  sudo cp $BACKUP/conf/80-libvirt.rules /etc/polkit-1/rules.d/
  sudo cp $BACKUP/conf/smb.conf /etc/samba/
  sudo cp -R $BACKUP/qemu/* /etc/libvirt/qemu/
  sudo mkdir -p /etc/libvirt/hooks && sudo cp $BACKUP/bin/qemu /etc/libvirt/hooks/
  yaourt -S --asdeps --noconfirm rpmextract
  cd /tmp
  rpmextract.sh $BACKUP/edk2.git-ovmf-x64-*.rpm
  sudo cp -R ./usr/share/* /usr/share/
  sudo rm -rf ./usr
  cd
  sudo ln -s $HOME/.card.sh /root/
fi

set +x
echo "UNINSTALLING LEFTOVER DEPENDENCIES..."
sleep 2
set -x
yaourt -Qtd

set +x
echo "SETTING UP GROUPS..."
sleep 2
set -x
sudo groupadd autologin
sudo usermod -aG disk,storage,network,audio,power,video,optical,wireshark,autologin,lp,sys $USER
if [ $(hostname) = "Death-Tower" ];
then
  sudo groupadd libvirtd
  sudo usermod -aG libvirtd,x2godesktopsharing $USER
  sudo smbpasswd -a $USER
fi

set +x
echo "DONE YO"
echo "CHECK FINAL FILE FOR MANUAL CONFIGS"
