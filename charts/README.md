# DevZero Self-Hosted - Helm Charts

This document outlines the steps to deploy the **DevZero Control Plane** and **Data Plane** using Helm charts. It includes configuration for both public and private network setups.

## Prerequisites

- **Kubernetes Cluster (EKS preferred)**
- **kubectl** configured with your cluster credentials
- **Helm 3.x** installed
- DockerHub credentials (contact [support@devzero.io](mailto:support@devzero.io))

## Deploying the Control Plane

### 1. Set Up kubeconfig

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### 2. Install Control Plane Dependencies

```bash
cd charts/dz-control-plane-deps
make install
```

For private subnet setups, modify `values/ingress-nginx_overrides.yaml`:

```yaml
controller:
  replicaCount: 1
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-subnets: <private_subnet_1>,<private_subnet_2>
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: <acm_cert_arn>
```

Update `values/grafana_overrides.yaml`:

```yaml
ingress:
  enabled: true
  hosts:
    - grafana.<domain>
  tls:
    - secretName: devzero-registry-tls
      hosts:
        - grafana.<domain>
```

Reinstall dependencies:

```bash
make install
```

### 3. Install the Control Plane

```bash
cd ../dz-control-plane
export DOCKERHUB_USERNAME=<dockerhub_username>
export DOCKERHUB_TOKEN=<dockerhub_token>
make add-docker-creds
make install
```

Update `values.yaml` with your domain, credentials, and license key.

For private networks without Let's Encrypt:

```yaml
ingress:
  enabled: true
  ingressClassName: "nginx"
  hosts:
    - host: "api.<domain>"
      paths:
        - path: /
          pathType: Prefix
```

### 4. DNS Setup

- Create **CNAME** and **A Records** in Route 53 pointing to the ingress service.

Verify installation:

```bash
kubectl get ingress -n devzero
```

Visit: `https://<your-dz-control-plane-web-host>/dashboard`

## Deploying the Data Plane

### 2. Install Data Plane Dependencies

```bash
git clone https://github.com/devzero-inc/self-hosted.git
cd self-hosted/charts/dz-data-plane-deps
make install
```

For private networks, modify `values/devzero-data-ingress_overrides.yaml`:

```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
      service.beta.kubernetes.io/aws-load-balancer-subnets: <private_subnet_1>,<private_subnet_2>
```

Apply changes:

```bash
make install
```

### 3. Install the Data Plane

```bash
cd ../dz-data-plane
make install
```

Update `values.yaml` with your credentials.

Monitor pods:

```bash
watch kubectl get pods -n devzero-self-hosted
```

### 4. DNS Setup

- Create **CNAME** and **A Records** in Route 53 for ingress services.

## Connecting to DevZero

1. Go to the DevZero dashboard → Regions → Add New.
2. Retrieve cluster information:

```bash
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}'
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
kubectl get serviceaccounts -n devzero-self-hosted
kubectl get secret <sa-token> -n devzero-self-hosted -o jsonpath='{.data.token}' | base64 -d
```

3. Add the retrieved details in the dashboard:
   - Cluster Name, Region ID, Cluster URL, CA Certificate, Service Account Token

To easily check requirements, install DevZero self-hosted, and validate the installation with CLI, refer to the [DevZero Installer README](../dz_installer/README.md).