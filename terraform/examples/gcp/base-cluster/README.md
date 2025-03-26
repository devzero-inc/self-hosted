

## Step 1: Navigate to the Terraform Directory

```bash
cd self-hosted/terraform/examples/gcp/base-cluster
```
### Authenticate to GCP
```bash
gcloud auth login
gcloud config set project devzero-kubernetes-sandbox
```

### Apply Terraform

```bash
terraform init
terraform apply -auto-approve
```

### Connect to GKE

```bash
gcloud container clusters get-credentials <cluster-name> --zone us-central1-a --project devzero-kubernetes-sandbox
```

### Install Kata in GKE Node

```bash
kubectl apply -f kata-sa.yaml
kubectl apply -f daemonset.yaml
```

### Add the Labels 

```bash
kubectl get nodes
kubectl label node <node-name> kata-runtime=running
kubectl label node <node-name> node-role.kubernetes.io/kata-devpod-node=1
```

Now you can install the DevZero Self-Hosted charts (dz-control-plane-deps, dz-control-plane, dz-data-plane-deps, dz-data-plane)

### Update Kata Runtime

After DSH installation, delete the default kata runtimeclass and create a new one:

```bash
kubectl delete runtimeclass kata
kubectl apply -f runtimeclass.yaml
```