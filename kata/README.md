# Kata AMI Build Process

This document outlines the process for building a custom Amazon Machine Image (AMI) for running Kata Containers. The AMI is tailored to support lightweight, secure virtualization with Kata Containers.

---

## Overview

The Kata AMI is a pre-configured Amazon Machine Image designed to run Kata Containers efficiently. It includes the required Kata runtime, kernel modules, and dependencies. The AMI is useful for deploying Kata Containers on AWS EC2 instances with minimal setup.

---

## Prerequisites

### Tools Required
- [HashiCorp Packer](https://www.packer.io/) (for automating the AMI build process)
- [AWS CLI](https://aws.amazon.com/cli/) (for managing AWS resources)
- Access credentials for your AWS account (IAM user/role with sufficient permissions)

### Base AMI Requirements
- **Amazon Linux 2**

---

## Step-by-Step Guide

### 1. Clone the Repository

```bash
git clone https://github.com/devzero-inc/self-hosted.git
```
### 2. Navigate to the linux-images Directory

```bash
cd self-hosted/kata/linux-images
```

### 3. Build and Run the Docker Container of the Host

```bash
docker build -t linux-image-host -f Dockerfile.host .
docker run -d --name linux-image-host linux-image-host
```

### 4. Copy the Package files to the Packer Directory

```bash
docker cp linux-image-host:/kernel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel.rpm
docker cp linux-image-host:/kernel-headers-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-headers.rpm
docker cp linux-image-host:/kernel-devel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-devel.rpm
```

### 5. Build and Run the Docker Container of the Guest

```bash
docker build -t linux-image-guest -f Dockerfile.guest .
docker run -d --name linux-image-guest linux-image-guest
```

### 6. Copy guest-vmlinux to the Packer Directory

```bash
docker cp linux-image-guest:/guest-vmlinux /packer
```

### 7. Build the AMI with Packer

```bash
packer init .
packer build .
```

#### Output

```bash
us-east-1: ami-wwwwxxxxyyyyzzzzz
us-east-2: ami-wwwwxxxxyyyyzzzzz
us-west-1: ami-wwwwxxxxyyyyzzzzz
us-west-2: ami-wwwwxxxxyyyyzzzzz
```

Copy the AMI of `ws-west-1` region.

### 5. Navigate to the Terraform to update the AMI for EC2 launch template

```bash
cd ../../terraform/examples/aws/simple-deployment
```

### 6. Paste the AMI in the EC2 launch template

In `main.tf`, replace the `ami_id` in the `eks_managed_node_groups` with the copied AMI.

```bash
ami_id = "ami-wwwwxxxxyyyyzzzzz"
```

### 7. Run the Terraform

```bash
terraform init
terraform apply
```

### 8. Update the kubeconfig

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### 9. Apply the Kata runtimeclass

```bash
cd ../../../../kata
kubectl apply -f runtimeclass.yaml
```


### 10. Set up the CRDs

```bash
helm pull oci://registry-1.docker.io/devzeroinc/dz-data-plane-crds
helm install dz-control-plane-crds oci://registry-1.docker.io/devzeroinc/dz-control-plane-crds -n devzero --create-namespace
```

### 11. Install the Control Plane

```bash
helm pull oci://registry-1.docker.io/devzeroinc/dz-control-plane
helm install dz-control-plane oci://registry-1.docker.io/devzeroinc/dz-control-plane -n devzero --set domain=<domain_name> --set issuer.email=support@devzero.io --set credentials.registry=docker.io/devzeroinc --set credentials.username=<username> --set credentials.password=<password> --set credentials.email=<email> --set backend.licenseKey=<license_key>
```