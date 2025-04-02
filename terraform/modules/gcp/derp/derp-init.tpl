#!/bin/bash
set -euxo pipefail
exec > /var/log/derp-init.log 2>&1

# Install dependencies
apt-get update
apt-get install -y curl git gcc make openssl certbot

# Install Go (use official binary)
wget -q https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz

# Set up Go env
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export PATH=$PATH:$GOPATH/bin
export HOME=/root
export GOCACHE=$HOME/.cache/go-build

# Install derper
go install tailscale.com/cmd/derper@main
cp $GOPATH/bin/derper /usr/bin/

%{ if !public_derp }
export DERP_PRIVATE_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
mkdir -p /etc/derper
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout /etc/derper/$DERP_PRIVATE_IP.key \
  -out /etc/derper/$DERP_PRIVATE_IP.crt \
  -subj "/CN=$DERP_PRIVATE_IP" \
  -addext "subjectAltName=IP:$DERP_PRIVATE_IP"
%{ endif }

# Create systemd service
cat <<EOT > /etc/systemd/system/derper.service
[Unit]
Description=Devzero DERP Server
After=network-online.target
Wants=network-online.target

[Service]
User=root
ExecStart=/usr/bin/derper %{ if public_derp }-hostname ${hostname}%{ else }-hostname \$DERP_PRIVATE_IP -certmode manual -certdir /etc/derper/ %{ endif }
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable derper
systemctl start derper
