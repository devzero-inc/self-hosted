################################################################################
# Common Outputs
################################################################################
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "region" {
  description = "The AWS region where the cluster is deployed"
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
# EKS Cluster Outputs
################################################################################
output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID for the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "The security group ID for the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "eks_cluster_version" {
  description = "The version of Kubernetes for the EKS cluster"
  value       = module.eks.cluster_version
}

################################################################################
# Vault Outputs
################################################################################
locals {
    vault_auto_unseal_key_output = <<-EOT
    seal "awskms" {
        kms_key_id = "${try(aws_kms_key.vault-auto-unseal[0].id, "")}"
        region = "${var.region}"
    }
    EOT
}
output "vault_auto_unseal_key_id" {
  value = var.create_vault_auto_unseal_key ? local.vault_auto_unseal_key_output : null
}
