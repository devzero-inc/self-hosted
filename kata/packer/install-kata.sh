#!/bin/bash

set -eu

DIR=$(mktemp -d)
trap "rm -r $DIR" EXIT

pushd "$DIR"
curl -fsSL -o kata-static.tar.xz https://github.com/kata-containers/kata-containers/releases/download/3.2.0/kata-static-3.2.0-amd64.tar.xz
tar -C / -xvf kata-static.tar.xz
ln -s /opt/kata/bin/kata-collect-data.sh /usr/local/bin/ || true
ln -s /opt/kata/bin/kata-runtime /usr/local/bin/ || true
curl -fsSL -o pvm-kata-stuff.tar.gz https://github.com/virt-pvm/misc/releases/download/test/pvm-kata-vm-img.tar.gz
tar -xvf pvm-kata-stuff.tar.gz
pushd pvm_img
mv containerd-shim-kata-v2 /opt/kata/bin/containerd-shim-kata-clh-v2
mv qemu-system-x86_64 /opt/kata/bin
popd

cat <<-EOF >/usr/local/bin/containerd-shim-kata-v2
#!/bin/bash
# Cloud Hypervisor shim
KATA_CONF_FILE=/etc/kata-containers/configuration-clh.toml /opt/kata/bin/containerd-shim-kata-clh-v2 \$@
EOF

chmod +x /usr/local/bin/containerd-shim-kata-v2

cat <<-EOF >/usr/local/bin/containerd-shim-kata-qemu-v2
#!/bin/bash
# QEMU shim
KATA_CONF_FILE=/etc/kata-containers/configuration-qemu.toml /opt/kata/bin/containerd-shim-kata-v2 \$@
EOF

chmod +x /usr/local/bin/containerd-shim-kata-qemu-v2

curl -fsSL -o /opt/kata/bin/cloud-hypervisor https://github.com/cloud-hypervisor/cloud-hypervisor/releases/download/v37.0/cloud-hypervisor-static
mkdir -p /etc/kata-containers
cp /tmp/configuration-clh.toml /etc/kata-containers/configuration-clh.toml
cp /tmp/configuration-qemu.toml /etc/kata-containers/configuration-qemu.toml
cp /tmp/vmlinux /opt/kata/share/kata-containers/vmlinux-6.7-pvm

mkdir -p /etc/containerd/config.d
mv /tmp/containerd.toml /etc/containerd/config.d/devzero.toml

cat <<EOF >/etc/modules-load.d/pvm.conf
kvm_pvm
EOF

popd
