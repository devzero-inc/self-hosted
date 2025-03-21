#!/bin/bash
set -euo pipefail

# Update system
apt-get update
apt-get install -y curl golang certbot openssl
export HOME=/home/ubuntu
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Install Tailscale
/usr/bin/go install tailscale.com/cmd/derper@main
cp /home/ubuntu/go/bin/derper /usr/bin/

%{ if !public_derp }
export DERP_PRIVATE_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
mkdir -p /etc/derper
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/derper/$DERP_PRIVATE_IP.key -out /etc/derper/$DERP_PRIVATE_IP.crt -subj "/CN=$DERP_PRIVATE_IP" -addext "subjectAltName=IP:$DERP_PRIVATE_IP"
%{ endif }

# Create systemd service
cat <<EOT > /etc/systemd/system/derper.service
[Unit]
Description=Devzero DERP Server
After=network-online.target
Wants=network-online.target

[Service]
User=root
ExecStart=/usr/bin/derper %{ if public_derp }-hostname ${hostname}%{ else }-hostname $DERP_PRIVATE_IP -certmode manual -certdir /etc/derper/ %{ endif }
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the service
systemctl daemon-reload
systemctl enable derper
systemctl start derper
