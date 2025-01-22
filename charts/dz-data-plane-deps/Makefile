include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) install-devzero-data-ingress

.PHONY: delete
delete:
	@$(MAKE)  delete-devzer-data-ingress

.PHONY: install-devzero-data-ingress
install-devzero-data-ingress:
	@$(MAKE) _install-helm-chart \
		APP_NAME=devzero-data-ingress \
		REPO_NAME=ingress-nginx \
		REPO_URL=https://kubernetes.github.io/ingress-nginx \
		REPO_APP_NAME=ingress-nginx \
		VERSION=4.11.3 \
		NAMESPACE=devzero-data-ingress

.PHONY: delete-devzero-data-ingress
delete-devzero-data-ingress:
	helm delete devzero-data-ingress -n devzero-data-ingress  --ignore-not-found
	kubectl delete namespace devzero-data-ingress --ignore-not-found=true

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
	helm delete rook-ceph -n devzero-rook --ignore-not-found
	kubectl get crds -o name | grep 'ceph.rook.io' | xargs kubectl delete
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
		NAMESPACE=dezvero-rook

.PHONY: delete-rook-ceph-cluster
delete-rook-ceph-cluster:
	helm delete rook-ceph-cluster -n dezvero-rook --ignore-not-found

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
	helm delete metacontroller -n devzero --ignore-not-found
	kubectl get crds -o name | grep 'metacontroller.k8s.io' | xargs kubectl delete

.PHONY: install-prometheus
install-prometheus:
	@$(MAKE) _install-helm-chart \
		APP_NAME=prometheus \
		REPO_NAME=prometheus-community \
		REPO_URL=https://prometheus-community.github.io/helm-charts \
		REPO_APP_NAME=prometheus \
		VERSION=26.0.1 \
		NAMESPACE=devzero

.PHONY: delete-prometheus
delete-prometheus:
	helm delete prometheus -n devzero --ignore-not-found
