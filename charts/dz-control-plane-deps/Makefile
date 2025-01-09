.PHONY: install
install:
	helm upgrade --install dz-self-hosted-deps -n devzero --create-namespace -f values.yaml .


.PHONY: delete
delete:
	helm delete dz-self-hosted-deps -n devzero


