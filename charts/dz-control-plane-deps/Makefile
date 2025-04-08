include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) _create-namespace NAMESPACE=devzero
	@$(MAKE) install-cert-manager
	@$(MAKE) install-ingress-nginx
	@$(MAKE) install-mysql-pulse
	@$(MAKE) install-mongodb
	@$(MAKE) install-redis
	@$(MAKE) install-devzero-db
	@$(MAKE) install-timescaledb
	@$(MAKE) install-elasticmq
	@$(MAKE) install-docker-registry
	@$(MAKE) install-mimir
	@$(MAKE) install-grafana
	@$(MAKE) install-vault

.PHONY: delete
delete:
	@$(MAKE) delete-cert-manager
	@$(MAKE) delete-ingress-nginx
	@$(MAKE) delete-mysql-pulse
	@$(MAKE) delete-mongodb
	@$(MAKE) delete-redis
	@$(MAKE) delete-devzero-db
	@$(MAKE) delete-timescaledb
	@$(MAKE) delete-elasticmq
	@$(MAKE) delete-docker-registry
	@$(MAKE) delete-mimir
	@$(MAKE) delete-grafana
	@$(MAKE) delete-vault
	@$(MAKE) _delete-namespace NAMESPACE=devzero

.PHONY: install-cert-manager
install-cert-manager:
	@$(MAKE) _install-helm-chart \
		APP_NAME=cert-manager \
		REPO_NAME=jetstack \
		REPO_URL=https://charts.jetstack.io \
		REPO_APP_NAME=cert-manager \
		VERSION=v1.16.2 \
		NAMESPACE=cert-manager
	@$(KUBECTL_BIN) apply -f cluster_issuer.yaml

.PHONY: delete-cert-manager
delete-cert-manager:
	@$(MAKE) _delete-chart \
		APP_NAME=cert-manager \
		REPO_NAME=jetstack \
		REPO_URL=https://charts.jetstack.io \
		REPO_APP_NAME=cert-manager \
		VERSION=v1.16.2 \
		NAMESPACE=cert-manager
	@$(KUBECTL_BIN) delete -f cluster_issuer.yaml --ignore-not-found=true
	@$(MAKE) _delete-namespace NAMESPACE=cert-manager
	@$(MAKE) _delete-crds CRD_NAME=cert-manager.io

.PHONY: install-ingress-nginx
install-ingress-nginx:
	@$(MAKE) _install-helm-chart \
		APP_NAME=ingress-nginx \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.12.1 \
		NAMESPACE=ingress-nginx

.PHONY: delete-ingress-nginx
delete-ingress-nginx:
	@$(MAKE) _delete-chart \
		APP_NAME=ingress-nginx \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.12.1 \
		NAMESPACE=ingress-nginx
	@$(MAKE) _delete-namespace NAMESPACE=ingress-nginx

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
	@$(MAKE) _delete-chart \
		APP_NAME=mysql-pulse \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mysql \
		VERSION=11.1.19 \
		NAMESPACE=devzero

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
	@$(MAKE) _delete-chart \
		APP_NAME=mongodb \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=mongodb \
		VERSION=16.4.0 \
		NAMESPACE=devzero

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
	@$(MAKE) _delete-chart \
		APP_NAME=redis \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=redis \
		VERSION=20.6.2 \
		NAMESPACE=devzero


.PHONY: install-devzero-db
install-devzero-db:
	@$(MAKE) _install-helm-chart \
		APP_NAME=devzero-db \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero \
		EXTRA_ARGS='--set primary.resources.requests.memory=512Mi \
		            --set primary.resources.limits.memory=1Gi'

.PHONY: delete-devzero-db
delete-devzero-db:
	@$(MAKE) _delete-chart \
		APP_NAME=devzero-db \
		REPO_NAME=bitnami \
		REPO_URL=https://charts.bitnami.com/bitnami \
		REPO_APP_NAME=postgresql \
		VERSION=16.3.5 \
		NAMESPACE=devzero


.PHONY: install-timescaledb
install-timescaledb:
	@$(MAKE) _install-helm-chart-default \
		APP_NAME=cnpg \
		REPO_NAME=cnpg \
		REPO_URL=https://cloudnative-pg.github.io/charts \
		REPO_APP_NAME=cloudnative-pg \
		VERSION=0.23.0 \
		NAMESPACE=devzero

	@$(KUBECTL_BIN) apply -f timescaledb-secret.yaml -n devzero

	@$(MAKE) _install-helm-chart \
		APP_NAME=timescaledb \
		REPO_NAME=cnpg \
		REPO_URL=https://cloudnative-pg.github.io/charts \
		REPO_APP_NAME=cluster \
		VERSION=0.2.1 \
		NAMESPACE=devzero


.PHONY: delete-timescaledb
delete-timescaledb:
	@$(MAKE) _delete-chart \
		APP_NAME=timescaledb \
		REPO_NAME=cnpg \
		REPO_URL=https://cloudnative-pg.github.io/charts \
		REPO_APP_NAME=cluster \
		VERSION=0.2.1 \
		NAMESPACE=devzero
	@$(KUBECTL_BIN) delete --ignore-not-found=true -f timescaledb-secret.yaml -n devzero
	@$(MAKE) _delete-chart \
		APP_NAME=cnpg \
		REPO_NAME=cnpg \
		REPO_URL=https://cloudnative-pg.github.io/charts \
		REPO_APP_NAME=cloudnative-pg \
		VERSION=0.23.0 \
		NAMESPACE=devzero
	@$(MAKE) _delete-crds CRD_NAME=postgresql.cnpg.io


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
	@$(MAKE) _delete-chart \
		APP_NAME=elasticmq \
		REPO_NAME=elasticmq \
		REPO_URL=https://chatwork.github.io/charts \
		REPO_APP_NAME=elasticmq \
		VERSION=0.2.0 \
		NAMESPACE=devzero

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
	@$(MAKE) _delete-chart \
		APP_NAME=docker-registry \
		REPO_NAME=docker-registry \
		REPO_URL=https://helm.twun.io \
		REPO_APP_NAME=docker-registry \
		VERSION=2.2.3 \
		NAMESPACE=devzero

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
	@$(MAKE) _delete-chart \
		APP_NAME=grafana \
		REPO_NAME=grafana \
		REPO_URL=https://grafana.github.io/helm-charts \
		REPO_APP_NAME=grafana \
		VERSION=8.8.2 \
		NAMESPACE=devzero

.PHONY: install-mimir
install-mimir:
	@$(MAKE) _install-helm-chart \
		APP_NAME=mimir \
		REPO_NAME=grafana \
		REPO_URL=https://grafana.github.io/helm-charts \
		REPO_APP_NAME=mimir-distributed \
		VERSION=5.6.0 \
		NAMESPACE=devzero

.PHONY: delete-mimir
delete-mimir:
	@$(MAKE) _delete-chart \
		APP_NAME=mimir \
		REPO_NAME=grafana \
		REPO_URL=https://grafana.github.io/helm-charts \
		REPO_APP_NAME=mimir-distributed \
		VERSION=5.6.0-weekly.321 \
		NAMESPACE=devzero

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
	@$(MAKE) _delete-chart \
		APP_NAME=vault \
		REPO_NAME=hashicorp \
		REPO_URL=https://helm.releases.hashicorp.com \
		REPO_APP_NAME=vault \
		VERSION=0.28.1 \
		NAMESPACE=devzero
