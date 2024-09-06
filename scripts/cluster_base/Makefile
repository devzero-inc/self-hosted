ARCH = $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')

VM_NAME = dz_cluster
OUTPUT_IMAGE = dz-cluster-base-$(ARCH).qcow2

include ../make/lima.mk