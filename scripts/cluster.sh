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

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: 'apt-get' is not available on this system."
  echo "The devzero data plane installation requires a Debian-based system (e.g., Ubuntu) with 'apt-get'."
  echo "Alternatively, install on a system that supports the KVM kernel module for KVM-based installation."
  exit 1
fi

if [ ! -f /etc/devzero/CLUSTER_SETUP ]; then
  # install prerequisites
  sudo apt-get update -y 
  sudo apt-get install iptables conntrack apt-transport-https gpg ca-certificates curl wget jq conmon -y
  install -m 0755 -d /etc/apt/keyrings

  # Add Docker's official GPG key:
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y

  # Path to the containerd configuration file
  CONFIG_FILE="/etc/containerd/config.toml"

  # Use sed to remove the line containing 'disabled_plugins = ["cri"]'
  sudo sed -i '/disabled_plugins = \["cri"\]/d' "$CONFIG_FILE"

  # Restart containerd to apply the changes
  sudo systemctl restart containerd

  # install minikube
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${arch}
  sudo install minikube-linux-${arch} /usr/local/bin/minikube && rm minikube-linux-${arch}
  sudo ln -s /bin/false /usr/local/bin/docker || true # bug in minikube
  sudo mkdir -p /etc/containerd && sudo touch /etc/containerd/config.toml

  # install cri-tools
  VERSION="v1.29.0"
  curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-${arch}.tar.gz
  tar -xzvf crictl-$VERSION-linux-${arch}.tar.gz crictl
  sudo install crictl /usr/local/bin/crictl && rm crictl-$VERSION-linux-${arch}.tar.gz crictl

  # setup cni-plugins
  sudo rm -f /etc/cni/net.d/*.conf*
  CNI_PLUGIN_VERSION="v1.5.1"
  CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz" # change arch if not on amd64
  CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"

  curl -LO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
  sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
  sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
  rm "$CNI_PLUGIN_TAR"

  # setup cri-o
  sudo mkdir -p /etc/crio /etc/crio/crio.conf.d && sudo touch /etc/crio/crio.conf.d/02-crio.conf

  # install helm
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  sudo systemctl daemon-reload


  curl -fsSL -O https://downloads.nestybox.com/sysbox/releases/v0.6.4/sysbox-ce_0.6.4-0.linux_amd64.deb
  sudo dpkg -i sysbox-ce_0.6.4-0.linux_amd64.deb
  sudo systemctl enable --now sysbox-fs.service sysbox-mgr.service sysbox.service

  minikube start --driver=none --container-runtime=cri-o --kubernetes-version=v1.29.0 --cni=bridge --embed-certs --extra-config=kubeadm.node-name=minikube --extra-config=kubelet.hostname-override=minikube
  # Allow any user to modify kubeconfig
  sudo chmod o+w /etc/kubernetes/admin.conf

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
  kubectl label nodes --all sysbox-runtime=running

cat <<EOF > runtime.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: sysbox-runc
handler: sysbox-runc
scheduling:
  nodeSelector:
    sysbox-runtime: running
EOF

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

  while true; do
    output=$(kubectl get pods -A)

    # Check if the output is empty
    if [ -z "$output" ]; then
      echo "No pods found!"
      sleep 5  # Wait for 5 seconds before retrying
      continue  # Retry the loop
    fi

    # Check if any pod is not in Running status
    if echo "$output" | grep -v -E 'Running|STATUS'; then
      echo "One or more pods are not in Running status!"
      sleep 5  # Wait for 5 seconds before retrying
    else
      echo "All pods are in Running status!"
      break  # Exit the loop once all pods are Running
    fi
  done

  echo "Cluster setup complete!" 
  sudo mkdir -p /etc/devzero && sudo touch /etc/devzero/CLUSTER_SETUP
else
  minikube start --driver=none --container-runtime=cri-o --kubernetes-version=v1.29.0 --cni=bridge --embed-certs --extra-config=kubeadm.node-name=minikube --extra-config=kubelet.hostname-override=minikube
fi
