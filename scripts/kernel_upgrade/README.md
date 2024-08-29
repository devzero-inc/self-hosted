# DZ Kernel Upgrade

Ubuntu 22.04 ships with kernel 5.15, which requires shiftfs kernel module for Sysbox to work. On newer kernel versions, sysbox used ID-mapped mounts as shiftfs is deprecated.

## Steps

```
# start the lima vm
make start

# export an image
make image
```
