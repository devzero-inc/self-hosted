# DevZero Self-Hosted - Kata AMI

This document outlines the process for building a custom Amazon Machine Image (AMI) optimised for running Kata Containers. The AMI is tailored to support lightweight, secure virtualisation, making it ideal for Kubernetes workloads.

## Overview

The **Kata AMI** is a pre-configured Amazon Machine Image designed to efficiently run Kata Containers. It includes the necessary Kata runtime, kernel modules, and dependencies, simplifying the deployment of secure container environments on AWS EC2 instances.

## Prerequisites

### Tools Required
- [HashiCorp Packer](https://www.packer.io/) - Automates the AMI build process.
- [AWS CLI](https://aws.amazon.com/cli/) - Manages AWS resources.
- **AWS Access Credentials** - IAM user/role with sufficient permissions.

### Base AMI Requirements
- **Amazon Linux 2023** (used as the base image for AMI creation)

For infrastructure setup, refer to the [Terraform README](../terraform/README.md).

## AMI Build Process

### 1. Clone the Repository

```bash
git clone https://github.com/devzero-inc/self-hosted.git
cd self-hosted/kata/linux-images
```

### 2. Build the Host Environment

- Clone the Linux repository:
  ```bash
  git clone https://github.com/virt-pvm/linux.git
  ```
- Build and run the Docker container:
  ```bash
  docker build -t linux-image-host -f Dockerfile.host .
  docker run -d --name linux-image-host linux-image-host
  ```
- Copy package files to the Packer directory:
  ```bash
  docker cp linux-image-host:/kernel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel.rpm
  docker cp linux-image-host:/kernel-headers-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-headers.rpm
  docker cp linux-image-host:/kernel-devel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-devel.rpm
  ```

### 3. Build the Guest Environment

```bash
docker build -t linux-image-guest -f Dockerfile.guest .
docker run -d --name linux-image-guest linux-image-guest
docker cp linux-image-guest:/guest-vmlinux /packer
```

### 4. Build the AMI with Packer

```bash
packer init .
packer build .
```

Upon successful build, Packer will output AMI IDs for multiple AWS regions:

```bash
us-east-1: ami-xxxxxxxxxxxxxxxxx
us-west-1: ami-yyyyyyyyyyyyyyyyy
```

## Integrating the AMI with Terraform

1. **Navigate to the Terraform Deployment Directory:**
   ```bash
   cd ../../terraform/examples/aws/base-cluster
   ```

2. **Update the AMI ID:**
   In `main.tf`, replace the existing `ami_id` under `module "kata_node_group"` with the new AMI ID:
   ```bash
   ami_id = "ami-xxxxxxxxxxxxxxxxx"
   ```

3. **Deploy the Infrastructure:**
   ```bash
   terraform init
   terraform apply
   ```

For detailed Terraform setup instructions, refer to the [Terraform README](../terraform/README.md).

## Kubernetes Configuration

1. **Update the kubeconfig:**
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

2. **Apply the Kata RuntimeClass:**
   ```bash
   kubectl apply -f runtimeclass.yaml
   ```

## Control Plane and CRD Setup

To deploy the DevZero Control Plane and Data Plane refer to the [Charts README](../charts/README.md).

## Troubleshooting

- Ensure all required tools are installed and up-to-date.
- Validate AWS credentials and permissions.
- Use `packer build -debug` for more detailed AMI build logs.
- For Terraform issues, run `terraform plan` to diagnose configuration errors.

