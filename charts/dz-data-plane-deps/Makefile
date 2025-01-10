include ../Makefile.common

.PHONY: install
install:
	@$(MAKE) install-rook-ceph
	@$(MAKE) install-rook-ceph-cluster

.PHONY: delete
delete:
	@$(MAKE) delete-rook-ceph-cluster
	@$(MAKE) delete-rook-ceph

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
