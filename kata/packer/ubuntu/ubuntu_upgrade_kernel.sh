#!/bin/bash

set -e

# Get kernel version
KERNEL_VERSION=$(dpkg --list | grep '^ii' | grep 'linux-image' | grep 'pvm-host' | awk '{print $2}' | sed 's/linux-image-//')
echo "Detected kernel version: ${KERNEL_VERSION}"

# Backup existing configs
sudo cp /etc/default/grub /etc/default/grub.backup
sudo cp /etc/default/grub.d/50-cloudimg-settings.cfg /etc/default/grub.d/50-cloudimg-settings.cfg.backup

# Install kernel packages
echo "Installing kernel packages..."
sudo dpkg -i /tmp/*.deb

# Configure AWS drivers for initramfs
echo "Configuring AWS drivers..."
sudo tee /etc/initramfs-tools/modules <<"EOF"
ena
nvme
nvme_core
xen-blkfront
EOF

# Disable initrdless boot
sudo sed -i 's/GRUB_FORCE_PARTUUID=.*/GRUB_FORCE_PARTUUID=""/' /etc/default/grub.d/40-force-partuuid.cfg

# Update GRUB settings
sudo tee /etc/default/grub <<"EOF"
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux 6.7.0-rc6-dz-pvm-host"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nokaslr pti=off console=tty1 console=ttyS0 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0"
GRUB_CMDLINE_LINUX="quiet splash nokaslr pti=off console=tty1 console=ttyS0 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0"
EOF

# Regenerate initramfs with AWS drivers
echo "Regenerating initramfs..."
sudo update-initramfs -c -k 6.7.0-rc6-dz-pvm-host

# sudo grub-set-default "Advanced options for Ubuntu>Ubuntu, with Linux 6.7.0-rc6-dz-pvm-host"

# sudo grub-editenv list

# Update GRUB
echo "Updating GRUB configuration..."
sudo update-grub

echo "Kernel upgrade complete! New kernel version: ${KERNEL_VERSION}"
echo "System ready for reboot"

