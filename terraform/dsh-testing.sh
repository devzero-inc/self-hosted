#!/bin/bash

set -e   

apply_terraform() {
  echo "Initializing Terraform..."
  if [[ "$TF_BACKEND" == "S3" ]]; then
    terraform init -backend-config="bucket=${BUCKET_NAME}" \
                   -backend-config="key=devzero/terraform.tfstate" \
                   -backend-config="region=us-west-1"
  else
    terraform init
  fi
  echo "Applying Terraform configuration..."
  terraform apply -auto-approve
}

get_eks_info() {
  CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
  AWS_REGION=$(terraform output -raw region)
}

configure_kubeconfig() {
  aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
}

login_to_helm_registry() {
  helm registry login registry.devzero.io --username $DZ_USERNAME --password $DZ_PASSWORD
}

install_devzero_crds() {
  helm install dz-control-plane-crds oci://registry.devzero.io/devzero-control-plane/beta/dz-control-plane-crds \
    -n devzero --create-namespace
}

install_devzero_control_plane() {
  helm install dz-control-plane oci://registry.devzero.io/devzero-control-plane/beta/dz-control-plane \
    -n devzero --set domain=$DOMAIN_NAME --set issuer.email=$EMAIL
}

get_ingress_service() {
  kubectl get ingress -n devzero
}

cleanup() {
  echo "Cleaning up resources..."
  terraform destroy -auto-approve
  echo "Resources cleaned up."
}

main() {
  trap cleanup EXIT

  cd examples/aws/control-and-data-plane

  apply_terraform

  get_eks_info

  configure_kubeconfig

  # login_to_helm_registry

  # install_devzero_crds

  # install_devzero_control_plane

  # get_ingress_service

  echo "DevZero control plane testing completed successfully!"
}

main

