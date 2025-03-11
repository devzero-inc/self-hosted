################################################################################
# Common Outputs
################################################################################
output "cluster_name" {
  description = "The name of the GKE cluster"
  value = module.gke.name
}

output "region" {
  description = "The GCP region where the cluster is deployed"
  value       = var.region
}

################################################################################
# VPC Outputs
################################################################################
output "vpc_id" {
  description = "The ID of the VPC where the cluster is deployed"
  value       = local.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.calculated_public_subnets_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.calculated_private_subnets_ids
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = local.effective_vpc_cidr_block
}

################################################################################
# GKE Cluster Outputs
################################################################################
output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.endpoint
}

output "cluster_master_version" {
  description = "The Kubernetes version of the GKE cluster"
  value = module.gke.master_version
}

output "node_pool_names" {
  description = "Names of the GKE node pools"
  value = module.gke.node_pools_names
}

################################################################################
# Vault Outputs (GCP KMS)
################################################################################
locals {
    vault_auto_unseal_key_output = <<-EOT
    seal "gcpckms" {
        project     = "${var.project_id}"
        location    = "global"
        key_ring    = "vault-auto-unseal"
        crypto_key  = "${try(google_kms_crypto_key.vault_key[0].name, "")}"
    }
    EOT
}
output "vault_auto_unseal_key_id" {
  value = var.create_vault_auto_unseal_key ? local.vault_auto_unseal_key_output : null
}
