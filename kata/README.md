# DevZero Self-Hosted - Kata AMI

This document outlines the process for building a custom Amazon Machine Image (AMI) optimised for running Kata Containers. The AMI is tailored to support lightweight, secure virtualisation, making it ideal for Kubernetes workloads.

## Overview

The **Kata AMI** is a pre-configured Amazon Machine Image designed to efficiently run Kata Containers. It includes the necessary Kata runtime, kernel modules, and dependencies, simplifying the deployment of secure container environments on AWS EC2 instances.

## Prerequisites

### Tools Required
- [HashiCorp Packer](https://www.packer.io/) - Automates the AMI build process.
- [AWS CLI](https://aws.amazon.com/cli/) - Manages AWS resources.
- **AWS Access Credentials** - IAM user/role with sufficient permissions.

### Base AMI Options
- **Amazon Linux 2023** 
- **Ubuntu 22.04**

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

  <details open>
  <summary>For AL2023</summary>
   
   ```bash
   docker build -t linux-image-host -f Dockerfile.host .
   docker run -d --name linux-image-host linux-image-host
   ```
   </details>
   <details>
   <summary>For Ubuntu</summary>
   
   ```bash
   docker build -t linux-image-host -f Dockerfile.ubuntu-host .
   docker run -d --name linux-image-host linux-image-host
   ```
   </details> 
   <br>
- Copy package files to the Packer directory:

  <details open>
  <summary>For AL2023</summary>
   
   ```bash
   docker cp linux-image-host:/kernel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel.rpm
   docker cp linux-image-host:/kernel-headers-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-headers.rpm
   docker cp linux-image-host:/kernel-devel-6.7.0_dz_pvm_host-1.x86_64.rpm /packer/kernel-devel.rpm
   ```
   </details>
   <details>
   <summary>For Ubuntu</summary>
   
   ```bash
   docker cp linux-image-host:/linux-image-6.7.0-rc6-dz-pvm-host_6.7.0-rc6-g040ea4a66ec9-1_amd64.deb /packer/ubuntu/kernel-image.deb
   docker cp linux-image-host:/linux-headers-6.7.0-rc6-dz-pvm-host_6.7.0-rc6-g040ea4a66ec9-1_amd64.deb /packer/ubuntu/kernel-headers.deb
   docker cp linux-image-host:/linux-libc-dev_6.7.0-rc6-g040ea4a66ec9-1_amd64.deb /packer/ubuntu/kernel-libc-dev.deb
   ```
   </details> 

### 3. Build the Guest Environment

<details open>
<summary>For AL2023</summary>

```bash
docker build -t linux-image-guest -f Dockerfile.guest .
docker run -d --name linux-image-guest linux-image-guest
docker cp linux-image-guest:/guest-vmlinux /packer 
```
</details>
<details>
<summary>For Ubuntu</summary>

```bash
docker build -t linux-image-guest -f Dockerfile.ubuntu-guest .
docker run -d --name linux-image-guest linux-image-guest
docker cp linux-image-guest:/guest-vmlinux /packer/ubuntu 
```
</details> 

### 4. Build the AMI with Packer

<details open>
<summary>For AL2023</summary>

```bash
cd ../packer 
packer init .
packer build --var-file=private.pkrvars.hcl eks-al2023.pkr.hcl 
```
</details>
<details>
<summary>For Ubuntu</summary>

```bash
cd ../packer/ubuntu 
packer init .
packer build --var-file=private.pkrvars.hcl eks-ubuntu.pkr.hcl
```
</details>
<br>

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

   <details open>
   <summary>For AL2023</summary>

      In `main.tf`, replace the existing `ami_id` under `module "kata_node_group"` with the new AMI ID:

      ```bash
      ami_id = "ami-xxxxxxxxxxxxxxxxx"
      ```
   </details>
   <details>
   <summary>For Ubuntu</summary>

      In `main.tf`, replace the existing `ami_id` under `module "ubuntu_kata_node_group"` with the new AMI ID:
      
      ```bash
      ami_id = "ami-xxxxxxxxxxxxxxxxx"
      ```
   </details> 
   <br>

3. **Deploy the Infrastructure:**

   <details open>
   <summary>For AL2023</summary>

      ```bash
      terraform init
      terraform apply
      ```
   </details>
   <details>
   <summary>For Ubuntu</summary>

      ```bash
      terraform init
      terraform apply -var="base_image=ubuntu"
      ```
   </details> 
   <br>

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

