# DevZero Data Plane Self Hosted Chart

## Installation

```bash
helm install dz-data-plane oci://public.ecr.aws/v1i4e1r2/charts/dz-data-plane \
  -n devzero-self-hosted \
  --version 0.1.3 \
  --set cedana-helm.cedanaConfig.signozAccessToken=<CEDANA_SIGNOZ_ACCESS_TOKEN> \
  --set cedana-helm.cedanaConfig.cedanaAuthToken=<CEDANA_AUTH_TOKEN> \
  --set devzero.teamId=<TEAM_ID> \
  --set devzero.region=<REGION>
```

Get the credentials to connect your DevZero Data Plane to the Control Plane.

```bash
kubectl get secret devzero-sa-token -n devzero-self-hosted -o jsonpath='{.data.token}' | base64 -d
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}'
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
```

### Node Labeling

The cluster has a node labeler DaemonSet that labels all nodes with the following labels:

- "node-role.kubernetes.io/devpod-node"=1
- "node-role.kubernetes.io/vcluster-node"=1
- "node-role.kubernetes.io/rook-node"=1

This means that all nodes in the cluster will be able to run Workspaces, Clusters, and Storage.

To separate resources into different node groups, disable the node labeler DaemonSet and label nodes manually:

```bash
--set sysbox.nodeLabeler.enabled=false
```

### Namespace

If using a namespace other than `devzero-self-hosted`, set the namespace:

```bash
--set namespace=<NAMESPACE>
```

## Parameters

### Devzero

| Name             | Description     | Value |
| ---------------- | --------------- | ----- |
| `devzero.teamId` | Team identifier | `""`  |
| `devzero.region` | Base Region     | `""`  |

### Vault

| Name                   | Description  | Value                    |
| ---------------------- | ------------ | ------------------------ |
| `devzero.vault.server` | Vault server | `https://csi.devzero.io` |

### Node Labeler

| Name                  | Description             | Value  |
| --------------------- | ----------------------- | ------ |
| `nodeLabeler.enabled` | Is node labeler enabled | `true` |

### Credentials Configuration

| Name                   | Description            | Value |
| ---------------------- | ---------------------- | ----- |
| `credentials.registry` | Container registry URL | `""`  |
| `credentials.username` | Registry username      | `""`  |
| `credentials.password` | Registry password      | `""`  |
| `credentials.email`    | Registry email address | `""`  |
