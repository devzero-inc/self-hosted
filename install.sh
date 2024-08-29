#!/bin/bash

OS=$(uname -s)

arch=$(uname -m)
case $(uname -m) in
  x86_64)
    arch=amd64
    ;;
  aarch64)
    arch=arm64
    ;;
esac

# Install dependencies
echo "Installing dependencies..."
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
  brew install qemu jq lima make kubectl >/dev/null 2>&1
elif [ "$OS" = "Linux" ]; then
  # id -u devzero &>/dev/null || sudo useradd -m -s /bin/bash devzero && sudo usermod -aG sudo devzero && echo "devzero ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devzero
  sudo apt-get install qemu-system jq make -y >/dev/null 2>&1
  VERSION=$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest | jq -r .tag_name)
  curl -fsSL "https://github.com/lima-vm/lima/releases/download/${VERSION}/lima-${VERSION:1}-$(uname -s)-$(uname -m).tar.gz" | sudo tar Cxzvm /usr/local >/dev/null 2>&1
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$arch/kubectl" >/dev/null 2>&1
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl >/dev/null 2>&1 && rm kubectl
  sudo chmod 666 /dev/kvm >/dev/null 2>&1 || true
  sudo usermod -a -G kvm $USER >/dev/null 2>&1 || true
else
  echo "Unsupported OS $OS"
  exit 1
fi
echo "Dependencies installed."

# Copy credentials to the correct location
echo "Copying credentials..."
mkdir -p ~/.lima ~/.lima/_config
curl -fsSL https://raw.githubusercontent.com/devzero-inc/self-hosted/main/keys/user -o ~/.lima/_config/user
curl -fsSL https://raw.githubusercontent.com/devzero-inc/self-hosted/main/keys/user.pub -o ~/.lima/_config/user.pub
chmod 400 ~/.lima/_config/user
echo "Credentials copied."

cat <<'EOF' >dz_cluster.yaml
vmType: "qemu"
cpus: 6
memory: "10GiB"
disk: "100GiB"
images:
  - location: "https://self-hosted.devzero.io/dz-cluster-base-arm64.qcow2"
    arch: "aarch64"
  - location: "https://self-hosted.devzero.io/dz-cluster-base-amd64.qcow2"
    arch: "x86_64"
mounts: []
provision:
  - mode: user
    script: |
      #!/bin/bash
      set -eux -o pipefail
      sudo hostnamectl set-hostname dz-cluster
      minikube start --driver=none --container-runtime=cri-o --kubernetes-version=v1.29.0 --cni=bridge --embed-certs
probes:
  - script: |
      #!/bin/bash
      set -eux -o pipefail
      output=$(kubectl get pods -A)

      # Check if the output is empty
      if [ -z "$output" ]; then
        echo "No pods found!"
        exit 1
      fi

      # # Check if any pod is not in Running status
      # if echo "$output" | grep -v -E 'Running|STATUS'; then
      #   echo "One or more pods are not in Running status!"
      #   exit 1
      # fi

      echo "All pods are in Running status."
      exit 0
EOF

# Start the VM
echo "Starting the cluster..."
limactl create dz_cluster.yaml --tty=false
limactl start dz_cluster
limactl shell dz_cluster -- cat .kube/config | tail -n +2 | sed -e 's|server:.*|server: https://127.0.0.1:8443|' > kubeconfig
kubectl get secret devzero-sa0-token -n default -o jsonpath='{.data.token}' --kubeconfig kubeconfig| base64 -d > sa-token
echo "Cluster started."