# DevZero Self-Hosted - Terraform Setup - GCP

This document provides a step-by-step guide for setting up the infrastructure required to self-host the DevZero Control Plane and Data Plane using Terraform. The infrastructure can be deployed on cloud platforms like GCP.

## Pre-reading

For readers experienced with Terraform deployments at their companies, we have some examples under [./examples](./examples/) that you can reference to see how to run a full DevZero deployment.
If you have your own terraform environment and want to reuse our modules, you can refer to the [./modules](./modules/) directory to use whichever components you need.

## Overview

The `terraform/` directory contains Infrastructure as Code (IaC) configurations that automate the provisioning of essential cloud resources such as VPCs, EKS clusters, load balancers, and VPNs.

## Prerequisites

### Tools Required
- [Terraform](https://www.terraform.io/) (for managing infrastructure as code)
- [GCloud CLI](https://cloud.google.com/sdk/docs/install) (for interacting with GCP resources)
- Access credentials for your GCP Account

### Permissions Required
Ensure your IAM user or service account has sufficient permissions to create resources like VPCs, subnets, GKE clusters, VMs, and KMS.

## Infrastructure Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/devzero-inc/self-hosted.git
```

### 2. Navigate to the Base Cluster Directory

```bash
cd self-hosted/terraform/examples/gcp/base-cluster
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

- This will create GCP resources such as VPC, GKE, VM, KMS, etc.
- Copy the output values like project_id, location, and cluster_name for the next steps.

## Extending the Cluster

### 5. Navigate to the Cluster Extensions Directory

```bash
cd ../cluster-extensions
```

### 6. Update `terraform.tfvars`

- Add the project_id, location, and cluster_name from the previous step.

### 7. Apply Terraform for Storage

```bash
terraform init
terraform apply
```

- This will create StorageClasses, and Filestore.

## Post-Deployment Steps

### 8. Update kubeconfig

```bash
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
```

### 9. Install Kata in GKE Node

```bash
kubectl apply -f kata-sa.yaml
kubectl apply -f daemonset.yaml
```

### 10. Add the Labels 

```bash
kubectl get nodes
kubectl label node <node-name> kata-runtime=running
kubectl label node <node-name> node-role.kubernetes.io/kata-devpod-node=1
```

### 11. Install DevZero Self-Hosted

Refer to the [Charts README](../charts/README.md) for further steps to deploy the Control Plane and Data Plane.

### 12. Update Kata Runtime

After DSH installation, delete the default kata runtimeclass and create a new one:

```bash
kubectl delete runtimeclass kata
kubectl apply -f runtimeclass.yaml
```

## Troubleshooting

- Verify cloud credentials and permissions.
- Check Terraform state files for resource management.
- Use `terraform plan` to preview changes before applying.


