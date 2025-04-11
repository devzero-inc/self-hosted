module "vault" {
  source = "../../../modules/vault"

  providers = {
    aws = aws
    kubernetes = kubernetes
  }

  cluster_ca_certificate = data.aws_eks_cluster.control-plane.certificate_authority[0].data
  cluster_host = data.aws_eks_cluster.control-plane.endpoint
  cluster_name = var.cluster_name
  domain = var.domain
  region = var.region
}