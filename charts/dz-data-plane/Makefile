include ../Makefile.common

.PHONY: install
install:
	helm upgrade --install devzero-data-plane . \
	--namespace devzero-self-hosted \
	--create-namespace \
	--values values.yaml

.PHONY: delete
delete:
	helm delete devzero-data-plane -n devzero-self-hosted --ignore-not-found

.PHONY: docs
docs:
	docker run --rm \
		--workdir /docs \
		-v $(PWD):/docs \
		devzeroinc/readme-generator-for-helm:latest /app/bin/readme-generator \
		--readme Readme.md \
		--values values.yaml \
		--schema values.schema.json

