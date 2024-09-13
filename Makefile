ARCH = $(shell uname -m)
VM_NAME = dz_cluster

include ./scripts/make/lima.mk

.PHONY: kubeconfig
kubeconfig:
	COMMAND="sudo -i -u devzero cat .kube/config" $(MAKE) shell --no-print-directory | tail -n +2 | sed -e 's|server:.*|server: https://127.0.0.1:8443|' > kubeconfig

.PHONY: sa-token
sa-token:
	kubectl get secret devzero-sa0-token -n default -o jsonpath='{.data.token}' | base64 -d > sa-token
