#!/bin/bash

set -e

sudo systemctl start containerd

# Download the images that are not available in the EKS distro before connecting to the cluster
# These images are hard coded here and duplicated into terraform so if this gets stale, terraform will still download those.
pull_image() {
  echo "Pulling image with ctr $1"
  ctr -n k8s.io images pull "$1" &
}

# github runner
pull_image "docker.io/devzeroinc/gha-scale-set-runner-ubuntu:24.04-devel@sha256:7eb16ed43cedd1a61a77e8e7f2ea073c426ac81d389b889d6e7f87e309ef33cf"

wait < <(jobs -p)
