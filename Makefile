ARCH = $(shell uname -m)
VM_NAME = dz_cluster

include ./scripts/make/lima.mk

.PHONY: kubeconfig
kubeconfig:
	limactl shell $(VM_NAME) sudo cat /etc/kubernetes/admin.conf | sed -e 's/control-plane.minikube.internal/127.0.0.1/' > kubeconfig
