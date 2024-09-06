ARCH = $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')

VM_NAME = kernel_upgrade
OUTPUT_IMAGE = jammy-$(ARCH)-kernel-6.8.qcow2

include ../make/lima.mk