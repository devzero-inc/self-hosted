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

.PHONY: docs
docs:
	docker run --rm -it \
		--workdir /docs \
		-v $(PWD):/docs \
		devzeroinc/readme-generator-for-helm:latest /app/bin/readme-generator \
		--readme Readme.md \
		--values values.yaml \
		--schema values.schema.json

