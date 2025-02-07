# DevZero Self-Hosted - Helm Charts - Control Plane Dependencies

This document provides instructions for deploying the **DevZero Control Plane Dependencies** in a self-hosted environment using Helm charts. These dependencies are crucial for supporting the control plane functionalities of the DevZero architecture, ensuring high availability, data management, security, and observability.

## Overview

The **DevZero Control Plane Dependencies Helm Chart** installs the following components:

1. **Cert-Manager:** Automates the management and issuance of TLS certificates.
2. **Ingress-NGINX:** Manages external access to services within the Kubernetes cluster.
3. **Databases:** Includes MySQL, MongoDB, Redis, PostgreSQL, and TimescaleDB for data storage.
4. **ElasticMQ:** Provides message queuing capabilities.
5. **Docker Registry:** Hosts container images internally.
6. **Grafana & Mimir:** Offers monitoring, metrics, and visualisation capabilities.
7. **Vault:** Manages secrets and sensitive data securely.

These components ensure secure communication, data persistence, application routing, monitoring, and secret management within the DevZero control plane.

## Prerequisites

- **Kubernetes Cluster (EKS preferred)**
- **kubectl** configured with your cluster credentials
- **Helm 3.x** installed
- DockerHub credentials (contact [support@devzero.io](mailto:support@devzero.io))

## Installation

1. **Clone the Repository:**

```bash
git clone https://github.com/devzero-inc/self-hosted.git
cd self-hosted/charts/dz-control-plane-deps
```

2. **Install All Dependencies:**

```bash
make install
```

### Install Components Individually

You can also install each dependency individually using the Makefile commands:

- **Cert-Manager:**
  ```bash
  make install-cert-manager
  ```

- **Ingress-NGINX:**
  ```bash
  make install-ingress-nginx
  ```

- **MySQL Pulse:**
  ```bash
  make install-mysql-pulse
  ```

- **MongoDB:**
  ```bash
  make install-mongodb
  ```

- **Redis:**
  ```bash
  make install-redis
  ```

- **Vault:**
  ```bash
  make install-vault
  ```

## Uninstallation

To delete all dependencies:

```bash
make delete
```

### Uninstall Components Individually

- **Cert-Manager:**
  ```bash
  make delete-cert-manager
  ```

- **Ingress-NGINX:**
  ```bash
  make delete-ingress-nginx
  ```

- **MySQL Pulse:**
  ```bash
  make delete-mysql-pulse
  ```

- **MongoDB:**
  ```bash
  make delete-mongodb
  ```

- **Vault:**
  ```bash
  make delete-vault
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
  - `cert-manager`
  - `ingress-nginx`
  - `mysql-pulse`
  - `mongodb`
  - `redis`
  - `vault`
  - ... (and others as needed)

- **Uninstall Specific Dependency:**
  ```bash
  make delete-<component>
  ```

## Troubleshooting

- Ensure Helm repositories are correctly configured.
- Check namespace status using `kubectl get ns`.
- Verify component status using `kubectl get pods -A`.
- Review Helm release status with `helm list -A`.