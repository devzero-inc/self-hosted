provider "aws" {
  region = var.region

  default_tags {
    tags = {
      CreatedBy: "DevZero"
    }
  }
}

data "aws_eks_cluster" "control-plane" {
  provider = aws
  name     = var.cluster_name
}

data "aws_eks_cluster_auth" "control-plane" {
  provider = aws
  name     = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.control-plane.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.control-plane.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.control-plane.token
}