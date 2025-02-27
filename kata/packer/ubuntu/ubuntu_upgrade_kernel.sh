#!/bin/bash

set -e

# Get kernel version
KERNEL_VERSION=$(dpkg-deb -f /tmp/kernel-image.deb Package | sed 's/linux-image-//')
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
sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Ubuntu>Ubuntu, with Linux ${KERNEL_VERSION}\"/" /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub

# Regenerate initramfs with AWS drivers
echo "Regenerating initramfs..."
sudo update-initramfs -c -k ${KERNEL_VERSION}

# Update GRUB
echo "Updating GRUB configuration..."
sudo update-grub

echo "Kernel upgrade complete! New kernel version: ${KERNEL_VERSION}"
echo "System ready for reboot"