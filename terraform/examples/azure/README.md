# DevZero Self-Hosted - Terraform Setup - Azure

This document provides a step-by-step guide for setting up the infrastructure required to self-host the DevZero Control Plane and Data Plane using Terraform. The infrastructure can be deployed on cloud platforms like Azure.

## Pre-reading

For readers experienced with Terraform deployments at their companies, we have some examples under [./examples](./examples/) that you can reference to see how to run a full DevZero deployment.
If you have your own terraform environment and want to reuse our modules, you can refer to the [./modules](./modules/) directory to use whichever components you need.

## Overview

The `terraform/` directory contains Infrastructure as Code (IaC) configurations that automate the provisioning of essential cloud resources such as VNet, AKS clusters, load balancers, and VPNs.

## Prerequisites

### Tools Required
- [Terraform](https://www.terraform.io/) (for managing infrastructure as code)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (for interacting with Azure resources)
- Access credentials for your Azure Account

### Permissions Required
Ensure your IAM user or service account has sufficient permissions to create resources like VNet, subnets, AKS clusters, VMs, and Key Vault.

## Infrastructure Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/devzero-inc/self-hosted.git
```

### 2. Navigate to the Base Cluster Directory

```bash
cd self-hosted/terraform/examples/azure/base-cluster
```

### 3. Configure Terraform Variables

Update `terraform.tfvars`.

#### Cluster Endpoint Access
- Set `cluster_endpoint_public_access = true` to allow public access.
- Set it to `false` for private access.

### 4. Initialise and Apply Terraform

```bash
terraform init
terraform apply
```

- This will create Azure resources such as VNet, AKS, VM, Key Vault, etc.
- Copy the output values like subscription_id, resource_group_name, location, and cluster_name for the next steps.

## Extending the Cluster

### 5. Navigate to the Cluster Extensions Directory

```bash
cd ../cluster-extensions
```

### 6. Update `terraform.tfvars`

- Add the subscription_id, resource_group_name, location, and cluster_name from the previous step.

### 7. Apply Terraform for Storage

```bash
terraform init
terraform apply
```

- This will create StorageClasses, and Azure Files.

## Post-Deployment Steps

### 8. Update kubeconfig

```bash
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
```

### 9. Install Kata in AKS Node

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

Or you can automatically label all your nodes like this:

```bash
for NODE in $(kubectl get nodes -o name); do
    kubectl label "$NODE" kata-runtime=running --overwrite
    kubectl label "$NODE" node-role.kubernetes.io/kata-devpod-node=1 --overwrite
done
```

### 11. Install DevZero Self-Hosted

Refer to the [Charts README](../charts/README.md) for further steps to deploy the Control Plane and Data Plane.

## Troubleshooting

- Verify cloud credentials and permissions.
- Check Terraform state files for resource management.
- Use `terraform plan` to preview changes before applying.
