#!/bin/bash

set -e

# Set non-interactive frontend
export DEBIAN_FRONTEND=noninteractive

# Pre-answer debconf questions
echo 'containerd.io containerd/restart-without-asking boolean true' | debconf-set-selections
echo 'containerd.io containerd/config_file string keep' | debconf-set-selections

# Install containerd if not present
if ! command -v containerd >/dev/null 2>&1; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install containerd non-interactively
    apt-get update
    apt-get install -y -o Dpkg::Options::="--force-confold" containerd.io
fi

# Configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Start containerd service
systemctl enable containerd
systemctl start containerd

# Download the images that are not available in the EKS distro before connecting to the cluster
# These images are hard coded here and duplicated into terraform so if this gets stale, terraform will still download those.
pull_image() {
  echo "Pulling image with ctr $1"
  ctr -n k8s.io images pull "$1" > /dev/null 2>&1 &
}

# github runner
pull_image "docker.io/devzeroinc/gha-scale-set-runner-ubuntu:24.04-devel@sha256:7eb16ed43cedd1a61a77e8e7f2ea073c426ac81d389b889d6e7f87e309ef33cf"

wait < <(jobs -p)
