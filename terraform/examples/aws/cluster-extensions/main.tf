data "aws_availability_zones" "available" {}

################################################################################
# Providers
################################################################################

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      CreatedBy: "DevZero"
    }
  }
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster-auth.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster-auth.token
  }
}

################################################################################

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name = data.aws_eks_cluster.this.id
}

module "cluster_extensions"{
  source = "../../../modules/aws/cluster_extensions"

  region = var.region
  cluster_name = var.cluster_name
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  enable_external_secrets = var.enable_external_secrets
}