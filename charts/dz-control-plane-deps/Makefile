include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) install-cert-manager
	@$(MAKE) install-ingress-nginx
	@#$(MAKE) install-devzero-control-ingress
	@$(MAKE) install-mysql-pulse
	@$(MAKE) install-mongodb
	@$(MAKE) install-redis
	@$(MAKE) install-postgres-logsrv
	@$(MAKE) install-postgres-hydra
	@$(MAKE) install-postgres-polland
	@$(MAKE) install-postgres-vault
	@$(MAKE) install-timescaledb-single
	@$(MAKE) install-elasticmq
	@$(MAKE) install-docker-registry
	@$(MAKE) install-grafana
	@$(MAKE) install-mimir-distributed
	@$(MAKE) install-vault

.PHONY: delete
delete:
	@$(MAKE) delete-cert-manager
	@$(MAKE) delete-ingress-nginx
	@#$(MAKE) delete-devzero-control-ingress
	@$(MAKE) delete-mysql-pulse
	@$(MAKE) delete-mongodb
	@$(MAKE) delete-redis
	@$(MAKE) delete-postgres-logsrv
	@$(MAKE) delete-postgres-hydra
	@$(MAKE) delete-postgres-polland
	@$(MAKE) delete-postgres-vault
	@$(MAKE) delete-timescaledb-single
	@$(MAKE) delete-elasticmq
	@$(MAKE) delete-docker-registry
	@$(MAKE) delete-grafana
	@$(MAKE) delete-mimir-distributed
	@$(MAKE) delete-vault

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
	helm delete cert-manager -n cert-manager --ignore-not-found
	kubectl delete namespace cert-manager --ignore-not-found=true
	kubectl get crds -o name | grep 'cert-manager.io' | xargs kubectl delete


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
	kubectl delete namespace ingress-nginx --ignore-not-found=true


.PHONY: install-devzero-control-ingress
install-devzero-control-ingress:
	@$(MAKE) _install-helm-chart \
		APP_NAME=devzero-control-ingress \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.11.3 \
		NAMESPACE=devzero-control-ingress

.PHONY: delete-devzero-control-ingress
delete-devzero-control-ingress:
	helm delete devzero-control-ingress -n devzero-control-ingress  --ignore-not-found
	kubectl delete namespace devzero-control-ingress --ignore-not-found=true



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

.PHONY: install-redis
install-redis:
	@$(MAKE) _install-helm-chart \
		APP_NAME=redis \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=redis \
		VERSION=20.6.2 \
		NAMESPACE=devzero

.PHONY: delete-redis
delete-redis:
	helm delete redis -n devzero --ignore-not-found

.PHONY: install-postgres-logsrv
install-postgres-logsrv:
	@$(MAKE) _install-helm-chart \
		APP_NAME=postgres-logsrv \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero

.PHONY: delete-postgres-logsrv
delete-postgres-logsrv:
	helm delete postgres-logsrv -n devzero --ignore-not-found

.PHONY: install-postgres-hydra
install-postgres-hydra:
	@$(MAKE) _install-helm-chart \
		APP_NAME=postgres-hydra \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero

.PHONY: delete-postgres-hydra
delete-postgres-hydra:
	helm delete postgres-hydra -n devzero --ignore-not-found

.PHONY: install-postgres-polland
install-postgres-polland:
	@$(MAKE) _install-helm-chart \
		APP_NAME=postgres-polland \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero

.PHONY: delete-postgres-polland
delete-postgres-polland:
	helm delete postgres-polland -n devzero --ignore-not-found

.PHONY: install-postgres-vault
install-postgres-vault:
	@$(MAKE) _install-helm-chart \
		APP_NAME=postgres-vault \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero

.PHONY: delete-postgres-vault
delete-postgres-vault:
	helm delete postgres-vault -n devzero --ignore-not-found

.PHONY: install-timescaledb-single
install-timescaledb-single:
	@$(MAKE) _install-helm-chart \
		APP_NAME=timescaledb-single \
		REPO_NAME=timescale \
		REPO_URL=https://charts.timescale.com \
		REPO_APP_NAME=timescaledb-single \
		VERSION=0.33.1 \
		NAMESPACE=devzero

.PHONY: delete-timescaledb-single
delete-timescaledb-single:
	helm delete timescaledb-single -n devzero --ignore-not-found

.PHONY: install-elasticmq
install-elasticmq:
	@$(MAKE) _install-helm-chart \
		APP_NAME=elasticmq \
		REPO_NAME=elasticmq \
		REPO_URL=https://chatwork.github.io/charts \
		REPO_APP_NAME=elasticmq \
		VERSION=0.2.0 \
		NAMESPACE=devzero

.PHONY: delete-elasticmq
delete-elasticmq:
	helm delete elasticmq -n devzero --ignore-not-found

.PHONY: install-docker-registry
install-docker-registry:
	@$(MAKE) _install-helm-chart \
		APP_NAME=docker-registry \
		REPO_NAME=docker-registry \
		REPO_URL=https://helm.twun.io \
		REPO_APP_NAME=docker-registry \
		VERSION=2.2.3 \
		NAMESPACE=devzero

.PHONY: delete-docker-registry
delete-docker-registry:
	helm delete docker-registry -n devzero --ignore-not-found

.PHONY: install-grafana
install-grafana:
	@$(MAKE) _install-helm-chart \
		APP_NAME=grafana \
		REPO_NAME=grafana \
		REPO_URL=https://grafana.github.io/helm-charts \
		REPO_APP_NAME=grafana \
		VERSION=8.8.2 \
		NAMESPACE=devzero

.PHONY: delete-grafana
delete-grafana:
	helm delete grafana -n devzero --ignore-not-found

.PHONY: install-mimir-distributed
install-mimir-distributed:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mimir-distributed \
		REPO_NAME=grafana \
		REPO_URL=https://grafana.github.io/helm-charts \
		REPO_APP_NAME=mimir-distributed \
		VERSION=5.6.0-weekly.321 \
		NAMESPACE=devzero

.PHONY: delete-mimir-distributed
delete-mimir-distributed:
	helm delete mimir-distributed -n devzero --ignore-not-found

.PHONY: install-vault
install-vault:
	@$(MAKE) _install-helm-chart \
		APP_NAME=vault \
		REPO_NAME=hashicorp \
		REPO_URL=https://helm.releases.hashicorp.com \
		REPO_APP_NAME=vault \
		VERSION=0.28.1 \
		NAMESPACE=devzero

.PHONY: delete-vault
delete-vault:
	helm delete vault -n devzero --ignore-not-found
