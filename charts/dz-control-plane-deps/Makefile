.PHONY: install
install:
	helm upgrade --install dz-self-hosted-deps -n devzero --create-namespace -f values.yaml .

.PHONY: delete
delete:
	helm delete dz-self-hosted-deps -n devzero


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

.PHONY: delete-cert-manager
delete-cert-manager:
	kubectl get crds -o name | grep 'cert-manager.io' | xargs kubectl delete
	helm delete cert-manager -n cert-manager --ignore-not-found
	kubectl delete namespace cert-manager


.PHONY: install-ingress-nginx
install-ingress-nginx:
	@$(MAKE) _install-helm-chart \
		APP_NAME=ingress-nginx \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.11.3 \
		NAMESPACE=ingress-nginx

.PHONY: delete-ingress-nginx
delete-ingress-nginx:
	helm delete ingress-nginx -n ingress-nginx  --ignore-not-found
	kubectl delete namespace ingress-nginx


.PHONY: install-mysql-polland
install-mysql-polland:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mysql-polland \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mysql \
		VERSION=11.1.19 \
		NAMESPACE=devzero

.PHONY: delete-mysql-polland
delete-mysql-polland:
	helm delete mysql-polland -n devzero --ignore-not-found

.PHONY: install-mysql-pulse
install-mysql-pulse:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mysql-pulse \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mysql \
		VERSION=11.1.19 \
		NAMESPACE=devzero

.PHONY: delete-mysql-pulse
delete-mysql-pulse:
	helm delete mysql-pulse -n devzero --ignore-not-found

.PHONY: install-mysql-vault
install-mysql-vault:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mysql-vault \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mysql \
		VERSION=11.1.19 \
		NAMESPACE=devzero

.PHONY: delete-mysql-vault
delete-mysql-vault:
	helm delete mysql-vault -n devzero --ignore-not-found

.PHONY: install-mongodb
install-mongodb:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mongodb \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mongodb \
		VERSION=16.4.0 \
		NAMESPACE=devzero

.PHONY: delete-mongodb
delete-mongodb:
	helm delete mongodb -n devzero --ignore-not-found

.PHONY: install-redis-backend
install-redis-backend:
	@$(MAKE) _install-helm-chart \
		APP_NAME=redis-backend \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=redis \
		VERSION=20.6.2 \
		NAMESPACE=devzero

.PHONY: delete-redis-backend
delete-redis-backend:
	helm delete redis-backend -n devzero --ignore-not-found


.PHONY: install-redis-hydra
install-redis-hydra:
	@$(MAKE) _install-helm-chart \
		APP_NAME=redis-hydra \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=redis \
		VERSION=20.6.2 \
		NAMESPACE=devzero

.PHONY: delete-redis-hydra
delete-redis-hydra:
	helm delete redis-hydra -n devzero --ignore-not-found

.PHONY: install-redis-polland
install-redis-polland:
	@$(MAKE) _install-helm-chart \
		APP_NAME=redis-polland \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=redis \
		VERSION=20.6.2 \
		NAMESPACE=devzero

.PHONY: delete-redis-polland
delete-redis-polland:
	helm delete redis-polland -n devzero --ignore-not-found
