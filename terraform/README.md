# DevZero Self-Hosted - Terraform Setup

This document provides a step-by-step guide for setting up the infrastructure required to self-host the DevZero Control Plane and Data Plane using Terraform. The infrastructure can be deployed on cloud platforms like AWS, GCP, and Azure.

## Overview

The `terraform/` directory contains Infrastructure as Code (IaC) configurations that automate the provisioning of essential cloud resources such as VPCs, EKS clusters, load balancers, and VPNs.

## Prerequisites

### Tools Required
- [Terraform](https://www.terraform.io/) (for managing infrastructure as code)
- [AWS CLI](https://aws.amazon.com/cli/) (for interacting with AWS resources)
- Access credentials for your cloud provider (AWS/GCP/Azure)

### Permissions Required
Ensure your IAM user or role has sufficient permissions to create resources like VPCs, subnets, EKS clusters, ALBs, and VPNs.

## Infrastructure Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/devzero-inc/self-hosted.git
```

### 2. Navigate to the Base Cluster Directory

```bash
cd self-hosted/terraform/examples/aws/base-cluster
```

### 3. Configure Terraform Variables

#### Using an Existing VPC
- Open the `terraform.tfvars` file.
- Update the VPC ID and subnet IDs.
- Set `create_vpc = false` to prevent Terraform from creating a new VPC.

#### Let Terraform Create a New VPC
- Skip the above step.
- Ensure `create_vpc = true` (default setting).

#### Cluster Endpoint Access
- Set `cluster_endpoint_public_access = true` to allow public access.
- Set it to `false` for private access.

### 4. Initialise and Apply Terraform

```bash
terraform init
terraform apply
```

- This will create AWS resources such as VPC, EKS, ALB, VPN, etc.
- Copy the output values like cluster name, VPC ID, and subnet IDs for the next steps.

## Extending the Cluster

### 5. Navigate to the Cluster Extensions Directory

```bash
cd ../cluster-extensions
```

### 6. Update `terraform.tfvars`

- Add the VPC ID, subnet IDs, region, and EKS cluster name from the previous step.

### 7. Apply Terraform for Add-ons and Storage

```bash
terraform init
terraform apply
```

- This will create EKS Add-ons, Storage Classes, and EFS.

## Post-Deployment Steps

### 8. Update kubeconfig

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### 9. Apply the Kata RuntimeClass

```bash
cd ../../../kata
kubectl apply -f runtimeclass.yaml
```

### 10. Install DevZero Control Plane

Refer to the [Charts README](../charts/README.md) for further steps to deploy the Control Plane and Data Plane.

## Troubleshooting

- Verify cloud credentials and permissions.
- Check Terraform state files for resource management.
- Use `terraform plan` to preview changes before applying.


