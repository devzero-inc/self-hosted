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
  brew install qemu jq lima make kubectl yq
elif [ "$OS" = "Linux" ]; then
  # id -u devzero &>/dev/null || sudo useradd -m -s /bin/bash devzero && sudo usermod -aG sudo devzero && echo "devzero ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devzero
  sudo apt-get install qemu-system jq make -y
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
cp -r ./keys ~/.lima/_config
chmod 400 ~/.lima/_config/user
echo "Credentials copied."

# Start the VM
echo "Starting the cluster..."
limactl create dz_cluster.yaml --tty=false
limactl start dz_cluster
limactl shell dz_cluster -- cat .kube/config | tail -n +2 | sed -e 's|server:.*|server: https://127.0.0.1:8443|' > kubeconfig
echo "Data plane started."

# Install control plane
/bin/bash ./dz/run.sh

# Create cluster in polland
certificate_authority_data=$(cat kubeconfig | yq e '.clusters[0].cluster."certificate-authority-data"' -)
token=$(kubectl get secret devzero-sa0-token -n default -o jsonpath='{.data.token}' --kubeconfig kubeconfig| base64 -d)

docker compose -f ./dz/docker-compose.yml run polland ./manage.py shell_plus -c 'user = User.objects.get(email="devzero@devzero.io"); user.set_password("123123"); user.save();'
docker compose -f ./dz/docker-compose.yml run polland ./manage.py shell_plus -c "cluster, created = Cluster.objects.get_or_create(
  cluster_id=1,
  defaults={
      'name': 'minikube',
      'certificate_authority_data': \"$certificate_authority_data\",
      'server': 'https://host.docker.internal:8443',
      'service_account_name': 'devzero-sa0',
      'service_account_token': \"$token\",
      'slug': 'minikube'
  }
)
if not created:
  # Update the existing cluster with new values
  cluster.name = 'minikube'
  cluster.certificate_authority_data = \"$certificate_authority_data\"
  cluster.server = 'https://host.docker.internal:8443'
  cluster.service_account_name = 'devzero-sa0'
  cluster.service_account_token = \"$token\"
  cluster.slug = 'minikube'
  cluster.save()"