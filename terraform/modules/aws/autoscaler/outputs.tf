output "aws_iam_policy_arn" {
  value = aws_iam_policy.cluster_autoscaler.arn
}

output "kubernetes_deployment" {
  value = "${kubernetes_deployment.cluster_autoscaler.metadata.0.namespace}/${kubernetes_deployment.cluster_autoscaler.metadata.0.name}"
}