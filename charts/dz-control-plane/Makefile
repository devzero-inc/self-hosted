include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) _install-local-helm-chart-default \
		APP_NAME=devzero \
		NAMESPACE=devzero \
		VALUES=values.yaml

.PHONY: delete
delete:
	@$(MAKE) _delete-local-chart \
		APP_NAME=devzero \
		NAMESPACE=devzero \
		VALUES=values.yaml

.PHONY: docs
docs:
	docker run --rm \
		--workdir /docs \
		-v $(PWD):/docs \
		devzeroinc/readme-generator-for-helm:latest /app/bin/readme-generator \
		--readme README.md \
		--values values.yaml \
		--schema values.schema.json

.PHONY: add-docker-creds
add-docker-creds:
	$(KUBECTL_BIN) create secret docker-registry regcred \
	--docker-username=$(DOCKERHUB_USERNAME) \
	--docker-password=$(DOCKERHUB_TOKEN) \
	-n devzero --dry-run=client -o yaml | kubectl apply -f -

	$(KUBECTL_BIN) patch serviceaccount default \
	-p '{"imagePullSecrets": [{"name": "regcred"}]}' \
	--namespace=devzero


.PHONY: template
template:
	helm template devzero . \
	--namespace devzero \
	--create-namespace \
	--values values.yaml
