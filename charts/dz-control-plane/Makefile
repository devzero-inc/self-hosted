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


.PHONY: template
template:
	helm template devzero . \
	--namespace devzero \
	--create-namespace \
	--values values.yaml

.PHONY: add-docker-creds
add-docker-creds:
	# docker login ghcr.io -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
	kubectl create secret docker-registry regcred \
	--docker-username=devzeroinc \
	--docker-password=dckr_oat_xAAr84zTH6Jf5swtaO6VnJfngYaNAaHA \
	-n devzero --dry-run=client -o yaml | kubectl apply -f -

	kubectl patch serviceaccount default \
      -p '{"imagePullSecrets": [{"name": "regcred"}]}' \
      --namespace=devzero

