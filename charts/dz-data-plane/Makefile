include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) _install-local-helm-chart-default \
		APP_NAME=devzero-data-plane \
		NAMESPACE=devzero-self-hosted \
		VALUES=values.yaml

.PHONY: delete
delete:
	@$(MAKE) _delete-local-chart \
		APP_NAME=devzero-data-plane \
		NAMESPACE=devzero-self-hosted \
		VALUES=values.yaml

.PHONY: docs
docs:
	docker run --rm \
		--workdir /docs \
		-v $(PWD):/docs \
		devzeroinc/readme-generator-for-helm:latest /app/bin/readme-generator \
		--readme Readme.md \
		--values values.yaml \
		--schema values.schema.json

