#!/bin/bash

set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive

case $(uname -m) in
x86_64)
    arch=amd64
    ;;
aarch64)
    arch=arm64
    ;;
esac

# install prerequisites
sudo apt-get update -y 
sudo apt-get install iptables conntrack apt-transport-https gpg ca-certificates curl wget jq conmon -y
install -m 0755 -d /etc/apt/keyrings

# install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${arch}
sudo install minikube-linux-${arch} /usr/local/bin/minikube && rm minikube-linux-${arch}
sudo ln -s /bin/false /usr/local/bin/docker # bug in "none" driver
sudo mkdir -p /etc/containerd && sudo touch /etc/containerd/config.toml

# install cri-tools
VERSION="v1.29.0"
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-${arch}.tar.gz
tar -xzvf crictl-$VERSION-linux-${arch}.tar.gz crictl
sudo install crictl /usr/local/bin/crictl && rm crictl-$VERSION-linux-${arch}.tar.gz crictl

# setup cni-plugins
sudo mkdir -p /opt/cni && sudo ln -s /usr/local/libexec/cni /opt/cni/bin
sudo rm -f /etc/cni/net.d/*.conf*

# setup cri-o
sudo mkdir -p /etc/crio /etc/crio/crio.conf.d && sudo touch /etc/crio/crio.conf.d/02-crio.conf

# install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sudo systemctl daemon-reload

# Switch to the devzero user to continue execution
sudo chmod 666 /etc/kubernetes/admin.conf
sudo chmod 666 /etc/kubernetes/kubelet.conf
minikube start --kubernetes-version=1.29 --driver=none --container-runtime=containerd --cni=bridge --embed-certs

# Allow any user to modify kubeconfig
sudo chmod o+w /etc/kubernetes/admin.conf

kubectl label nodes --all node-role.kubernetes.io/devpod-node=1
kubectl label nodes --all sysbox-install=yes
kubectl apply -f https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml

until kubectl logs daemonset/sysbox-deploy-k8s -n kube-system | grep -q 'Sysbox installation completed'; do
sleep 10
done

minikube delete
minikube start --driver=none --container-runtime=cri-o --kubernetes-version=v1.29.0 --cni=bridge --embed-certs

# Path to your configuration file
CONFIG_FILE="/etc/crio/crio.conf"

# Add insecure_registries under [crio.image] if it doesn't exist
if grep -q "\[crio.image\]" "$CONFIG_FILE"; then
sudo sed -i "/\[crio.image\]/a\\      insecure_registries = [\"host.lima.internal:9997\"]" "$CONFIG_FILE"
else
sudo bash -c "printf '\n[crio.image]\n       insecure_registries = [\"host.lima.internal:9997\"]\n' >> \"$CONFIG_FILE\""
fi
sudo systemctl daemon-reload
sudo systemctl restart crio

# wait for cri-o to restart
until kubectl version >/dev/null 2>&1; do
sleep 10
done

kubectl label nodes --all node-role.kubernetes.io/devpod-node=1
kubectl label nodes --all sysbox-install=yes
kubectl apply -f https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml

kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/v0.9.20/deploy/crds/bundle.yaml

# add fake gp2 storage class
cat <<EOF > storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
name: gp2
labels:
    addonmanager.kubernetes.io/mode: EnsureExists
annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: k8s.io/minikube-hostpath
EOF
kubectl apply -f storage-class.yaml

# add generic device plugin
cat <<EOF > generic-device-plugin.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
name: generic-device-plugin
namespace: kube-system
labels:
    app.kubernetes.io/name: generic-device-plugin
spec:
selector:
    matchLabels:
    app.kubernetes.io/name: generic-device-plugin
template:
    metadata:
    labels:
        app.kubernetes.io/name: generic-device-plugin
    spec:
    priorityClassName: system-node-critical
    nodeSelector:
        node-role.kubernetes.io/devpod-node: "1"
    tolerations:
    - operator: "Exists"
        effect: "NoExecute"
    - operator: "Exists"
        effect: "NoSchedule"
    containers:
    - image: ghcr.io/squat/generic-device-plugin:${arch}-36bfc606bba2064de6ede0ff2764cbb52edff70d
        args:
        - --device
        - |
        name: tuntap
        groups:
            - count: 999
            paths:
                - path: /dev/net/tun
        name: generic-device-plugin
        resources:
        requests:
            cpu: 50m
            memory: 10Mi
        limits:
            cpu: 50m
            memory: 20Mi
        ports:
        - containerPort: 8080
        name: http
        volumeMounts:
        - name: device-plugin
        mountPath: /var/lib/kubelet/device-plugins
        - name: dev
        mountPath: /dev
    volumes:
    - name: device-plugin
        hostPath:
        path: /var/lib/kubelet/device-plugins
    - name: dev
        hostPath:
        path: /dev
updateStrategy:
    type: RollingUpdate
EOF
kubectl apply -f generic-device-plugin.yaml

cat <<EOF > service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
name: devzero-sa0
namespace: default
---
apiVersion: v1
kind: Secret
metadata:
name: devzero-sa0-token
namespace: default
annotations:
    kubernetes.io/service-account.name: devzero-sa0
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
name: devzero-sa0-cluster-admin-binding
subjects:
- kind: ServiceAccount
    name: devzero-sa0
    namespace: default
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: cluster-admin
EOF
kubectl apply -f service-account.yaml