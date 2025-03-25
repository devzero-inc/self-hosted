include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) install-devzero-data-ingress
	@$(MAKE) install-prometheus-operator
	@$(MAKE) install-prometheus

.PHONY: delete
delete:
	@$(MAKE) delete-devzero-data-ingress
	@$(MAKE) delete-prometheus
	@$(MAKE) delete-prometheus-operator

.PHONY: install-devzero-data-ingress
install-devzero-data-ingress:
	@$(MAKE) _install-helm-chart \
		APP_NAME=devzero-data-ingress \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.12.1 \
		NAMESPACE=devzero-data-ingress

.PHONY: delete-devzero-data-ingress
delete-devzero-data-ingress:
	@$(MAKE) _delete-chart \
		APP_NAME=devzero-data-ingress \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.12.1 \
		NAMESPACE=devzero-data-ingress
	@$(MAKE) _delete-namespace NAMESPACE=devzero-data-ingress

.PHONY: install-rook-ceph
install-rook-ceph:
	@$(MAKE) _install-helm-chart \
		APP_NAME=rook-ceph \
		REPO_NAME=rook-release \
		REPO_URL=https://charts.rook.io/release \
		REPO_APP_NAME=rook-ceph \
		VERSION=v1.14.9 \
		NAMESPACE=devzero-rook

.PHONY: delete-rook-ceph
delete-rook-ceph:
	@$(MAKE) _delete-chart \
		APP_NAME=rook-ceph \
		REPO_NAME=rook-release \
		REPO_URL=https://charts.rook.io/release \
		REPO_APP_NAME=rook-ceph \
		VERSION=v1.14.9 \
		NAMESPACE=devzero-rook
	@$(MAKE) _delete-crds CRD_NAME=ceph.rook.io
	#kubectl get clusterrole -o custom-columns=NAME:.metadata.name,ANNOTATION:.metadata.annotations.meta\\.helm\\.sh/release-name --no-headers | grep rook-ceph | xargs kubectl delete clusterrole
	#kubectl get clusterrolebinding -o custom-columns=NAME:.metadata.name,ANNOTATION:.metadata.annotations.meta\\.helm\\.sh/release-name --no-headers | grep rook-ceph | xargs kubectl delete clusterrolebinding
	#kubectl get clusterroles -l app.kubernetes.io/part-of=rook-ceph-operator -o name  | xargs kubectl delete
	#kubectl get clusterroles -o name| grep 'rook-ceph'  | xargs kubectl delete


.PHONY: install-rook-ceph-cluster
install-rook-ceph-cluster:
	@$(MAKE) _install-helm-chart \
		APP_NAME=rook-ceph-cluster \
		REPO_NAME=rook-release \
		REPO_URL=https://charts.rook.io/release \
		REPO_APP_NAME=rook-ceph-cluster \
		VERSION=v1.14.9 \
		NAMESPACE=devzero-rook

.PHONY: delete-rook-ceph-cluster
delete-rook-ceph-cluster:
	@$(MAKE) _delete-chart \
		APP_NAME=rook-ceph-cluster \
		REPO_NAME=rook-release \
		REPO_URL=https://charts.rook.io/release \
		REPO_APP_NAME=rook-ceph-cluster \
		VERSION=v1.14.9 \
		NAMESPACE=devzero-rook

.PHONY: install-metacontroller
install-metacontroller:
	@$(MAKE) _install-oci-helm-chart \
		APP_NAME=metacontroller \
		REPO_NAME=metacontroller-helm \
		REPO_URL=oci://ghcr.io/metacontroller \
		REPO_APP_NAME=metacontroller \
		VERSION=4.11.22 \
		NAMESPACE=devzero

.PHONY: delete-metacontroller
delete-metacontroller:
	@$(MAKE) _delete-chart \
		APP_NAME=metacontroller \
		REPO_NAME=metacontroller-helm \
		REPO_URL=oci://ghcr.io/metacontroller \
		REPO_APP_NAME=metacontroller \
		VERSION=4.11.22 \
		NAMESPACE=devzero
	@$(MAKE) _delete-crds CRD_NAME=metacontroller.k8s.io

.PHONY: install-prometheus-operator
install-prometheus-operator:
	@$(MAKE) _install-helm-chart \
		APP_NAME=prometheus-operator-crds \
		REPO_NAME=prometheus-community \
		REPO_URL=https://prometheus-community.github.io/helm-charts \
		REPO_APP_NAME=prometheus-operator-crds \
		VERSION=18.0.0 \
		NAMESPACE=devzero

.PHONY: delete-prometheus-operator
delete-prometheus-operator:
	@$(MAKE) _delete-chart \
		APP_NAME=prometheus-operator-crds \
		REPO_NAME=prometheus-community \
		REPO_URL=https://prometheus-community.github.io/helm-charts \
		REPO_APP_NAME=prometheus-operator-crds \
		VERSION=18.0.0 \
		NAMESPACE=devzero

.PHONY: install-prometheus
install-prometheus:
	@$(MAKE) _install-helm-chart \
		APP_NAME=prometheus \
		REPO_NAME=prometheus-community \
		REPO_URL=https://prometheus-community.github.io/helm-charts \
		REPO_APP_NAME=prometheus \
		VERSION=26.0.1 \
		NAMESPACE=devzero

	@$(KUBECTL_BIN) apply -f ./values/vclustermonitor.yaml -n devzero

.PHONY: delete-prometheus
delete-prometheus:
	@$(MAKE) _delete-chart \
		APP_NAME=prometheus \
		REPO_NAME=prometheus-community \
		REPO_URL=https://prometheus-community.github.io/helm-charts \
		REPO_APP_NAME=prometheus \
		VERSION=26.0.1 \
		NAMESPACE=devzero
