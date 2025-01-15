include ../Makefile.common

.PHONY: install
install:
	helm upgrade --install devzero . \
	--namespace devzero \
	--create-namespace \
	--values values.yaml

.PHONY: delete
delete:
	helm delete devzero -n devzero --ignore-not-found
