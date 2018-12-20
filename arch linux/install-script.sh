#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
set -e
echo "MAKE SURE YOU'RE IN WHEEL GROUP AND CAN USE SUDO AND HAVE INTERNET"
sleep 5

echo "INSTALLING PACKAGES..."
sleep 2
set -x
if [ "$(hostname)" != "$ROUTER" ]
then sudo cp -n $BACKUP/pkg/$ROUTER/*.pkg.tar* /var/cache/pacman/pkg/
fi
sudo cp -n $BACKUP/pkg/$(hostname)/*.pkg.tar* /var/cache/pacman/pkg/
# start with packages that hate --noconfirm (because they're a choice)
# for KDE/Plasma, add phonon-qt5-backend
sudo pacman -Sy libglvnd lib32-libglvnd ttf-font
# do AUR packages first since yaourt won't check cache
for i in $(<$BACKUP/pkg/$(hostname)/aur); do
  FILE="$(ls /var/cache/pacman/pkg/$i* | grep -P "$i-([0-9]|r[0-9]|latest)")"
  sudo pacman -U --noconfirm --needed $FILE
done
yaourt -S --noconfirm --noedit --needed $(<$BACKUP/pkg/$(hostname)/aur)
yaourt -S --noconfirm --noedit --needed $(<$BACKUP/pkg/$(hostname)/list)
yaourt -D --asexplicit $(<$BACKUP/pkg/$(hostname)/list)
yaourt -D --asexplicit $(<$BACKUP/pkg/$(hostname)/aur)
yaourt -D --asdeps $(<$BACKUP/pkg/$(hostname)/deps)

set +x
echo "SETTING UP SYSTEM..."
sleep 2
set -x
sudo cp -d $BACKUP/bin/local/* /usr/local/bin/
sudo cp -dR $BACKUP/ufw/ufw/* /etc/ufw/
sudo cp -dR $BACKUP/ufw/gufw/* /etc/gufw/
sudo systemctl enable ufw.service
sudo ufw enable
sudo systemctl enable lightdm.service
sudo systemctl enable NetworkManager.service
sudo systemctl enable ntpdate.service
sudo systemctl enable bluetooth
sudo systemctl enable udisks.service
echo HandleLidSwitch=ignore | sudo tee -a /etc/systemd/logind.conf
rm -rf $HOME/.adobe/Flash_Player/{NativeCache,AssetCache,APSPrivateData2}
sudo cp $BACKUP/conf/alsa-base.conf /etc/modprobe.d/
sudo mkdir -p /etc/openal
echo drivers=pulse,alsa | sudo tee -a /etc/openal/alsoft.conf
echo frequency=48000 | sudo tee -a /etc/openal/alsoft.conf
sudo cp $BACKUP/conf/snd_seq_midi.conf /etc/modules-load.d/
sudo cp $BACKUP/conf/uinput.conf /etc/modules-load.d/
sudo cp $BACKUP/conf/51-gcadapter.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo cp -R $HOME/.config /root/
sudo cp $HOME/Backup/Consoles/Wii\ \&\ Gamecube/dsp_*.bin /usr/share/dolphin-emu/sys/GC/
sudo cp $BACKUP/conf/51-gcadapter.rules /etc/udev/rules.d/
sudo ln -s /usr/lib/firefox /usr/lib/mozilla
sudo cp $BACKUP/conf/10-ptrace.conf /etc/sysctl.d/
sudo cp $BACKUP/conf/60-xwiimote.conf /etc/X11/xorg.conf.d/
sudo cp $BACKUP/conf/20-custom.conf /etc/X11/xorg.conf.d/
sudo cp $BACKUP/conf/engrampa.tap /usr/lib/xfce4/thunar-archive-plugin/
while read LINE; do
  LINE="$(echo $LINE | sed 's/\#.*//')"
  if [ "$LINE" != "" ]; then
    LINE="$(echo $LINE | sed 's/\W.*//')=$(echo $LINE | sed 's/.*DEFAULT=//')"
    if ! grep -Fxq "$LINE" /etc/environment ; then
      echo "$LINE" | sudo tee -a /etc/environment
    fi
  fi
done < $HOME/.pam_environment
if [ "$(hostname)" = "Death-Tower" ];
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
  sudo cp $BACKUP/conf/10-nouveau.conf /etc/X11/xorg.conf.d/
  sudo cp $BACKUP/conf/20-amdgpu.conf /etc/X11/xorg.conf.d/
  sudo cp $BACKUP/conf/vfio-pci.conf /etc/modprobe.d/
  sudo cp $BACKUP/conf/qemu.conf /etc/libvirt/
  sudo cp $BACKUP/conf/80-libvirt.rules /etc/polkit-1/rules.d/
  sudo cp $BACKUP/conf/smb.conf /etc/samba/
  sudo cp -dR $BACKUP/qemu/* /etc/libvirt/qemu/
  sudo mkdir -p /etc/libvirt/hooks && sudo cp $BACKUP/bin/qemu /etc/libvirt/hooks/
  yaourt -S --asdeps --noconfirm rpmextract
  DIR=$(pwd)
  cd /tmp
  rpmextract.sh $BACKUP/edk2.git-ovmf-x64-*.rpm
  sudo cp -a ./usr/share/* /usr/share/
  sudo rm -rf ./usr
  cd "$DIR"
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
if [ "$(hostname)" = "Death-Tower" ];
then
  sudo groupadd libvirtd
  sudo usermod -aG libvirtd,x2godesktopsharing $USER
  sudo smbpasswd -a $USER
fi

set +x
echo "DONE YO"
echo "CHECK FINAL FILE FOR MANUAL CONFIGS"
