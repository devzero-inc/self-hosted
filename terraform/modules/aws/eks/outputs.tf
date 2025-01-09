output "region" {
  description = "AWS region"
  value       = var.region
}

output "endpoint" {
  description = "AWS EKS cluster endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "version" {
  description = "The Kubernetes version for the cluster"
  value       = try(aws_eks_cluster.this.version, null)
}

output "certificate-authority-data" {
  description = "EKS Kubernetes authority data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "name" {
  description = "EKS id/name"
  value       = aws_eks_cluster.this.id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = flatten(concat(aws_eks_cluster.this[*].identity[*].oidc.0.issuer, [""]))[0]
}

output "cluster_ca_certificate" {
  value = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

output "aws_eks_cluster_auth_token" {
  value = data.aws_eks_cluster_auth.cluster.token
}

output "provider_url" {
  value = replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")
}

output "provider_id" {
  value = aws_iam_openid_connect_provider.cluster.arn
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}
