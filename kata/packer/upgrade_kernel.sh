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
tee /etc/default/grub <<"EOF"
# Various settings which make debugging a custom kernel not a ginormous Pain In The Ass.
# You're welcome. - Ellie
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash console=tty1 console=ttyS0 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0"
GRUB_TERMINAL="ec2-console console serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
EOF
grub2-mkconfig -o /boot/grub2/grub.cfg


