# DevZero Self-Hosted - Helm Charts - Data Plane Dependencies

This document provides instructions for deploying the **DevZero Data Plane Dependencies** in a self-hosted environment using Helm charts. These dependencies are crucial for supporting the data layer functionalities of the DevZero architecture, ensuring high availability, observability, and seamless data management.

## Overview

The **DevZero Data Plane Dependencies Helm Chart** installs the following components:

1. **Ingress-NGINX:** Manages external access to services within the Kubernetes cluster.
2. **Rook-Ceph:** Provides distributed, highly available storage solutions for persistent data.
3. **Rook-Ceph Cluster:** Manages Ceph clusters for robust data storage management.
4. **Metacontroller:** Extends Kubernetes with custom controllers to enhance automation.
5. **Prometheus:** Offers powerful monitoring and alerting capabilities.

These components form the backbone of the data plane, ensuring efficient traffic routing, storage management, and observability.

## Prerequisites

- **Kubernetes Cluster (EKS preferred)**
- **kubectl** configured with your cluster credentials
- **Helm 3.x** installed
- DockerHub credentials (contact [support@devzero.io](mailto:support@devzero.io))

## Installation

1. **Clone the Repository:**

```bash
git clone https://github.com/devzero-inc/self-hosted.git
cd self-hosted/charts/dz-data-plane-deps
```

2. **Install All Dependencies:**

```bash
make install
```

Alternatively, you can install each component individually:

- **Ingress-NGINX:**
  ```bash
  make install-devzero-data-ingress
  ```

- **Rook-Ceph:**
  ```bash
  make install-rook-ceph
  ```

- **Rook-Ceph Cluster:**
  ```bash
  make install-rook-ceph-cluster
  ```

- **Metacontroller:**
  ```bash
  make install-metacontroller
  ```

- **Prometheus:**
  ```bash
  make install-prometheus
  ```

## Uninstallation

To delete all dependencies:

```bash
make delete
```

Or remove each component individually:

- **Ingress-NGINX:**
  ```bash
  make delete-devzero-data-ingress
  ```

- **Rook-Ceph:**
  ```bash
  make delete-rook-ceph
  ```

- **Rook-Ceph Cluster:**
  ```bash
  make delete-rook-ceph-cluster
  ```

- **Metacontroller:**
  ```bash
  make delete-metacontroller
  ```

- **Prometheus:**
  ```bash
  make delete-prometheus
  ```

## Makefile Commands

- **Install All Dependencies:**
  ```bash
  make install
  ```

- **Uninstall All Dependencies:**
  ```bash
  make delete
  ```

- **Install Specific Dependency:**
  ```bash
  make install-<component>
  ```
  Replace `<component>` with:
  - `devzero-data-ingress`
  - `rook-ceph`
  - `rook-ceph-cluster`
  - `metacontroller`
  - `prometheus`

- **Uninstall Specific Dependency:**
  ```bash
  make delete-<component>
  ```

## Troubleshooting

- Ensure Helm repositories are correctly configured.
- Check namespace status using `kubectl get ns`.
- Verify component status using `kubectl get pods -A`.


