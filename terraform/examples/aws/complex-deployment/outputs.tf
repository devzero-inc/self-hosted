output "region" {
  description = "AWS region"
  value       = var.region
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_node_groups" {
  value = module.eks.eks_managed_node_groups
}
