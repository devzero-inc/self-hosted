output "region" {
  description = "AWS region"
  value       = var.region
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
