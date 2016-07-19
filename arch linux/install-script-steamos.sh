#!/bin/bash
BACKUP=$HOME/Backup/Computers/Linux
INFO=$HOME/Dropbox/Settings/Scripts
ROUTER=$(sed -n 1p $INFO/$(sed -n 1p $INFO/ROUTER).info) # hostname of main computer & router
set -e
echo "ADD TO /etc/fstab"
echo "home	/home     	          9p      	trans=virtio	0 0"
echo "pkg 	/var/cache/pacman/pkg 9p      	trans=virtio	0 0"
echo "MAKE SURE YOU'RE IN WHEEL GROUP AND CAN USE SUDO AND HAVE INTERNET"
sleep 5

echo "INSTALLING PACKAGES..."
sleep 2
set -x
sudo cp $BACKUP/pkg/$ROUTER/*libgl*.tar.xz /var/cache/pacman/pkg/
sudo cp $BACKUP/pkg/$(hostname)/*libgl*.tar.xz /var/cache/pacman/pkg/
sudo pacman -Sy libgl lib32-libgl
sudo pacman -Rs gcc gcc-libs
sudo pacman -U --noconfirm $BACKUP/pkg/$ROUTER/pacaur*.tar.xz
sudo cp -n $BACKUP/pkg/$(hostname)/*.tar.xz /var/cache/pacman/pkg/
sudo cp -n $BACKUP/pkg/$ROUTER/*.tar.xz /var/cache/pacman/pkg/
sudo chmod 777 /var/cache/pacman/pkg
PKGDEST=/var/cache/pacman/pkg pacaur -S --noconfirm --noedit --needed $(<$BACKUP/pkg/$(hostname)/list)
sudo chmod 755 /var/cache/pacman/pkg
sudo pacman -D --asdeps $(<$BACKUP/pkg/$(hostname)/deps)

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
