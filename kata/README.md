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
### 2. Navigate to the Packer Directory

```bash
cd self-hosted/kata/packer
```

### 3. Install the necessary resources from S3

```bash
aws s3 cp s3://dz-pvm-artifacts/ . --recursive
```

### 4. Build the AMI with Packer

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
cd ../../terraform/modules/aws/eks/main.tf
```

### 6. Paste the AMI in the EC2 launch template

update the `Image_Id` in the EC2 luanch template with the copied AMI and run terraform

### 7. Run the Terraform

```bash
cd ../examples/aws/control-and-data-plane
terraform init
terraform apply
```
