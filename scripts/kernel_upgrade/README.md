# DZ Kernel Upgrade

Ubuntu 22.04 ships with kernel 5.15, which requires shiftfs kernel module for Sysbox to work. On newer kernel versions, sysbox used ID-mapped mounts as shiftfs is deprecated.

## Steps

```
# start the lima vm
make start

# shell into it
make shell

# check the linux kernel is there
dpkg --list | grep linux-image
# ii  linux-image-5.15.0-118-generic    5.15.0-118.128          Signed kernel image generic
# ii  linux-image-6.8.0-40-generic      6.8.0-40.40~22.04.3     Signed kernel image generic
# ii  linux-image-generic-hwe-22.04     6.8.0-40.40~22.04.3     Generic Linux kernel image
# ii  linux-image-virtual               5.15.0.118.118          Virtual Linux kernel image

uname -r
# 5.15.0-118-generic

# reboot to update
sudo reboot

# shell again
make shell

# check kernel is updated
uname -r
# 6.8.0-40-generic

# remove the unused kernels (first time usually installs some things, so run it two times)
sudo /remove_old_kernels.sh
sudo /remove_old_kernels.sh

dpkg --list | grep linux-image
# ii  linux-image-6.8.0-40-generic      6.8.0-40.40~22.04.3     Signed kernel image generic

# export an image
make image
```
