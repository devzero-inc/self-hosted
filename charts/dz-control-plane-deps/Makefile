.PHONY: install
install:
	helm upgrade --install dz-self-hosted-deps -n devzero --create-namespace -f values.yaml .

.PHONY: _install-helm-chart
_install-helm-chart:
	@helm repo add $(REPO_NAME) $(REPO_URL)
	@helm repo update $(REPO_NAME)
	helm upgrade --install $(APP_NAME) $(REPO_NAME)/$(REPO_APP_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--values values/$(APP_NAME).yaml \
		--values values/$(APP_NAME)_overrides.yaml

.PHONY: install-cert-manager
install-cert-manager:
	@$(MAKE) _install-helm-chart \
		APP_NAME=cert-manager \
		REPO_NAME=jetstack \
		REPO_URL=https://charts.jetstack.io \
		REPO_APP_NAME=cert-manager \
		VERSION=v1.16.2 \
		NAMESPACE=cert-manager

.PHONY: install-ingress-nginx
install-ingress-nginx:
	@$(MAKE) _install-helm-chart \
		APP_NAME=ingress-nginx \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.11.3 \
		NAMESPACE=ingress-nginx

.PHONY: delete
delete:
	helm delete dz-self-hosted-deps -n devzero

.PHONY: delete-cert-manager
delete-cert-manager:
	kubectl get crds -o name | grep 'cert-manager.io' | xargs kubectl delete
	helm delete cert-manager -n cert-manager
	kubectl delete namespace cert-manager

.PHONY: delete-ingress-nginx
delete-ingress-nginx:
	helm delete ingress-nginx -n ingress-nginx
	kubectl delete namespace ingress-nginx
