#!/bin/bash

set -e

# Download the images that are not available in the EKS distro before connecting to the cluster
# These images are hard coded here and duplicated into terraform so if this gets stale, terraform will still download those.
pull_image() {
  echo "Pulling image with ctr $1"
  ctr -n k8s.io images pull "$1" &
}

# falco
pull_image "docker.io/falcosecurity/falco-no-driver:0.38.0"
pull_image "docker.io/falcosecurity/falcoctl:0.8.0"
pull_image "docker.io/falcosecurity/k8s-metacollector:0.1.1"
# datadog
pull_image "gcr.io/datadoghq/cluster-agent:7.55.2"
pull_image "gcr.io/datadoghq/agent:7.55.2"
# vcluster
pull_image "public.ecr.aws/eks-distro/coredns/coredns:v1.10.1-eks-1-28-6"
pull_image "docker.io/flanksource/vcluster-sync-host-secrets:v0.1.6"
pull_image "ghcr.io/loft-sh/vcluster:0.16.4"
pull_image "public.ecr.aws/eks-distro/kubernetes/kube-apiserver:v1.28.2-eks-1-28-6"
pull_image "public.ecr.aws/eks-distro/kubernetes/kube-controller-manager:v1.28.2-eks-1-28-6"
pull_image "public.ecr.aws/eks-distro/etcd-io/etcd:v3.5.9-eks-1-28-6"
# external_secrets
pull_image "ghcr.io/external-secrets/external-secrets:v0.9.1"
# external_dns
pull_image "registry.k8s.io/external-dns/external-dns:v0.14.0"
# cert_manager
pull_image "quay.io/jetstack/cert-manager-controller:v1.13.3"
pull_image "quay.io/jetstack/cert-manager-cainjector:v1.13.3"
pull_image "quay.io/jetstack/cert-manager-webhook:v1.13.3"
# ingress_nginx
pull_image "registry.k8s.io/ingress-nginx/controller:v1.9.5"
# metrics_server
pull_image "registry.k8s.io/metrics-server/metrics-server:v0.7.0"
# sysbox
pull_image "ghcr.io/devzero-inc/sysbox-deploy-k8s:v0.6.4-devzero"
# generic_device_plugin
pull_image "ghcr.io/squat/generic-device-plugin:36bfc606bba2064de6ede0ff2764cbb52edff70d"
# ingress
pull_image "registry.k8s.io/ingress-nginx/controller:v1.9.5@sha256:b3aba22b1da80e7acfc52b115cae1d4c687172cbf2b742d5b502419c25ff340e"
# base_devbox
pull_image "public.ecr.aws/v1i4e1r2/devzero-devbox-base:base-latest"
# cedana
pull_image "docker.io/cedana/cedana-helper:v0.9.219"
pull_image "gcr.io/kubebuilder/kube-rbac-proxy:v0.14.1"
# ceph
pull_image "quay.io/cephcsi/cephcsi:v3.11.0"
pull_image "quay.io/ceph/ceph:v18.2.4"
pull_image "docker.io/rook/ceph:v1.14.9"
pull_image "registry.k8s.io/sig-storage/csi-resizer:v1.10.1"
pull_image "registry.k8s.io/sig-storage/csi-attacher:v4.5.1"

wait < <(jobs -p)
