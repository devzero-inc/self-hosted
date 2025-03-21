#!/bin/bash

set -e

echo "Upgrading kernel!"

# Install the downloaded packages
echo "Installing kernel packages..."
yum localinstall -y /tmp/*.rpm

echo "*****************************************************************************"
sudo find / -type f -name "vmlinuz-6.7.0-rc6+" 2>/dev/null

sudo find /boot /lib/modules /usr/src /var/tmp -type f -name "vmlinuz*" 2>/dev/null

grubby --info=ALL
echo "*****************************************************************************"

sudo grubby --add-kernel=/boot/vmlinuz-6.7.0-dz-pvm-host --title "Amazon Linux (6.7.0-rc6+)"


grubby --set-default /boot/vmlinuz-6.7.0-dz-pvm-host
grubby --args="quiet splash nokaslr pti=off console=tty1 console=ttyS0 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0" --update-kernel /boot/vmlinuz-6.7.0-dz-pvm-host

echo "Regenerating initramfs with ENA driver..."
sudo dracut -f --kernel-image '/boot/vmlinuz-6.7.0-dz-pvm-host' --kver '6.7.0-dz-pvm-host' --add-drivers "ena"

tee /etc/default/grub <<"EOF"
# Some settings to make debugging a custom kernel easier.
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nokaslr pti=off console=tty1 console=ttyS0 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0"
GRUB_TERMINAL="ec2-console console serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
GRUB_DEFAULT=saved
GRUB_UPDATE_DEFAULT_KERNEL=true
GRUB_ENABLE_BLSCFG="true"
EOF
grub2-mkconfig -o /boot/grub2/grub.cfg