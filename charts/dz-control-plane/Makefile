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
	docker run --rm \
		--workdir /docs \
		-v $(PWD):/docs \
		devzeroinc/readme-generator-for-helm:latest /app/bin/readme-generator \
		--readme Readme.md \
		--values values.yaml \
		--schema values.schema.json

.PHONY: add-docker-creds
add-docker-creds:
	kubectl create secret docker-registry regcred \
	--docker-username=$(DOCKERHUB_USERNAME) \
	--docker-password=$(DOCKERHUB_TOKEN) \
	-n devzero --dry-run=client -o yaml | kubectl apply -f -

	kubectl patch serviceaccount default \
	-p '{"imagePullSecrets": [{"name": "regcred"}]}' \
	--namespace=devzero
