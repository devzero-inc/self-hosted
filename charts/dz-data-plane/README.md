# DevZero Self-Hosted - Helm Charts - Data Plane

This document provides instructions for deploying the **DevZero Data Plane** in a self-hosted environment using Helm charts. The Helm chart automates the deployment of all necessary components, ensuring seamless integration with the DevZero Control Plane.

## Overview

The **DevZero Data Plane Helm Chart** installs essential components to support the data layer of DevZero's self-hosted architecture. It includes workloads like:

- **Workspaces:** Isolated environments for development tasks.
- **Clusters:** Managed Kubernetes resources.
- **Storage:** Integrated with Rook-Ceph for persistent data management.

The chart also handles service account configurations, node labelling, and secure communication with the Control Plane.

## Prerequisites

- **Kubernetes Cluster (EKS preferred)**
- **kubectl** configured with your cluster credentials
- **Helm 3.x** installed
- DockerHub credentials (contact [support@devzero.io](mailto:support@devzero.io))


## Installation

1. **Clone the Repository:**

```bash
git clone https://github.com/devzero-inc/self-hosted.git
cd self-hosted/charts/dz-data-plane
```

2. **Install the Data Plane:**

```bash
make install
```

Alternatively, using Helm directly:

```bash
helm install dz-data-plane oci://public.ecr.aws/v1i4e1r2/charts/dz-data-plane \
  -n devzero-self-hosted \
  --version 0.1.3 \
  --set cedana-helm.cedanaConfig.signozAccessToken=<CEDANA_SIGNOZ_ACCESS_TOKEN> \
  --set cedana-helm.cedanaConfig.cedanaAuthToken=<CEDANA_AUTH_TOKEN> \
  --set devzero.teamId=<TEAM_ID> \
  --set devzero.region=<REGION>
```

3. **Configure Values:**

Edit `values.yaml` to provide your specific configurations:

```yaml
devzero:
  teamId: "<TEAM_ID>"
  region: "<REGION>"
credentials:
  registry: "<REGISTRY_URL>"
  username: "<USERNAME>"
  password: "<PASSWORD>"
  email: "<EMAIL>"
```

## Retrieving Connection Credentials

After installation, retrieve the credentials needed to connect the Data Plane to the Control Plane:

```bash
kubectl get secret devzero-sa-token -n devzero-self-hosted -o jsonpath='{.data.token}' | base64 -d
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}'
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
```

## Node Labelling

The Helm chart deploys a **Node Labeler DaemonSet** to label cluster nodes automatically, enabling them to support different workloads:

- `node-role.kubernetes.io/devpod-node=1`
- `node-role.kubernetes.io/vcluster-node=1`
- `node-role.kubernetes.io/rook-node=1`

To disable automatic labelling and manage labels manually:

```bash
--set nodeLabeler.enabled=false
```

## Custom Namespace Deployment

By default, the chart deploys to the `devzero-self-hosted` namespace. To use a custom namespace, change the helm command:

```bash
--namespace <NAMESPACE>
```

## Helm Chart Components

The Helm chart installs the following components:

1. **DevZero Data Plane Services:** Core services to manage data plane operations.
2. **Rook-Ceph:** Provides distributed storage for persistent data.
3. **Ingress Controllers:** For managing external access to services.
4. **Service Accounts and RBAC:** Secure role-based access management.
5. **Monitoring Tools:** Integrates with Prometheus and Cedana for observability.

## Makefile Commands

- **Install the Data Plane:**
  ```bash
  make install
  ```
- **Uninstall the Data Plane:**
  ```bash
  make delete
  ```
- **Generate Documentation:**
  ```bash
  make docs
  ```


## Parameters

### DevZero Configuration

| Name               | Description          | Value             |
| ------------------ | -------------------- | ----------------- |
| `devzero.teamId`   | Team identifier      | `""`              |
| `devzero.region`   | Deployment region    | `""`              |

### Vault Configuration

| Name                   | Description      | Value                    |
| ---------------------- | ---------------- | ------------------------ |
| `devzero.vault.server` | Vault server URL | `https://csi.devzero.io` |

### Node Labeler

| Name                  | Description               | Value  |
| --------------------- | ------------------------- | ------ |
| `nodeLabeler.enabled` | Enable/disable node labeler | `true` |

### Credentials Configuration

| Name                   | Description              | Value |
| ---------------------- | ------------------------ | ----- |
| `credentials.registry` | Container registry URL   | `""`  |
| `credentials.username` | Registry username        | `""`  |
| `credentials.password` | Registry password        | `""`  |
| `credentials.email`    | Registry email address   | `""`  |

## Uninstallation

To uninstall the DevZero Data Plane:

```bash
make delete
```

Or via Helm:

```bash
helm delete dz-data-plane -n devzero-self-hosted
```


