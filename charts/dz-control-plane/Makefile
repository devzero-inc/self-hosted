include ../Makefile.common

.PHONY: install
install:
	helm upgrade --install devzero-control-plane . \
	--namespace devzero \
	--create-namespace \
	--values values.yaml

.PHONY: delete
delete:
	helm delete devzero-control-plane -n devzero --ignore-not-found
