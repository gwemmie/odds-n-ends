#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/ROUTER) # hostname of main computer & router
set -e
echo "ADD TO /etc/fstab"
echo "home	/home     	          9p      	trans=virtio	0 0"
echo "pkg 	/var/cache/pacman/pkg 9p      	trans=virtio	0 0"
echo "MAKE SURE YOU'RE IN WHEEL GROUP AND CAN USE SUDO AND HAVE INTERNET"
sleep 5

echo "INSTALLING PACKAGES..."
sleep 2
set -x
sudo cp -n $BACKUP/pkg/$ROUTER/*.tar.xz /var/cache/pacman/pkg/
sudo cp -n $BACKUP/pkg/$(hostname)/*.tar.xz /var/cache/pacman/pkg/
# start with packages that hate --noconfirm (because they're a choice)
# for KDE/Plasma, add phonon-qt5-backend
sudo pacman -Sy libgl lib32-libgl gcc-multilib gcc-libs-multilib ttf-font
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
systemctl --user enable pulseaudio.service
sudo systemctl enable avahi-daemon # for pulseaudio streaming
sudo systemctl enable dhcpcd.service
sudo systemctl enable xlogin@$USER.service
sudo systemctl enable sshd.socket
sudo systemctl enable x2goserver.service
sudo sed -i 's/my $lines=`ss -lxu`;/my $lines=`ss -lx`;/' /usr/bin/x2golistdesktops
sudo mkdir -p /etc/openal
echo drivers=pulse,alsa | sudo tee -a /etc/openal/alsoft.conf
echo frequency=48000 | sudo tee -a /etc/openal/alsoft.conf
sudo cp -d $BACKUP/bin/local/* /usr/local/bin/
sudo cp $BACKUP/conf/9p-virtio.conf /etc/modules-load.d/
sudo cp $HOME/Backup/Consoles/Wii\ \&\ Gamecube/dsp_*.bin /usr/share/dolphin-emu/sys/GC/
sudo cp $BACKUP/conf/51-gcadapter.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
#sudo cp $BACKUP/conf/asound.conf /etc/
echo "fs.file-max=1000000" | sudo tee -a /etc/sysctl.conf
echo "* soft nofile 1000000" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 1000000" | sudo tee -a /etc/security/limits.conf

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
sudo usermod -aG autologin,sys,audio,x2godesktopsharing $USER

set +x
echo "DONE YO"
echo "CHECK FINAL FILE FOR MANUAL CONFIGS"
