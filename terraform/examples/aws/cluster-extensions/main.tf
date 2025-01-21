locals {
  private_subnet_cidr_blocks = [for subnet in data.aws_subnet.private_subnets : subnet.cidr_block]

  public_subnet_cidr_blocks = [for subnet in data.aws_subnet.public_subnets : subnet.cidr_block]

  effective_vpc_cidr_block = data.aws_vpc.existing.cidr_block
}

data "aws_availability_zones" "available" {}

################################################################################
# Providers
################################################################################

provider "tls" {}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster-data" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name = data.aws_eks_cluster.cluster-data.id
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.cluster-data.identity[0].oidc[0].issuer
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster-data.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-data.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster-auth.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster-data.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-data.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster-auth.token
  }
}


################################################################################
# Common resources
################################################################################

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = !(var.vpc_id == null)
      error_message = "The variable vpc_id must be set"
    }

    precondition {
      condition     = !(length(var.private_subnet_ids) == 0)
      error_message = "The variable private_subnets must be set"
    }

    precondition {
      condition     = !(length(var.public_subnet_ids) == 0)
      error_message = "The variable public_subnets must be set"
    }
  }
}

data "aws_subnet" "private_subnets" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public_subnets" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

data "aws_vpc" "existing" {
  id    = var.vpc_id
}

################################################################################
# EKS Blueprints Addons
################################################################################
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.51.0"

  role_name_prefix = "${data.aws_eks_cluster.cluster-data.id}-ebs-csi-driver-"

  attach_ebs_csi_policy = true
  policy_name_prefix    = data.aws_eks_cluster.cluster-data.id

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"

  cluster_name      = data.aws_eks_cluster.cluster-data.id
  cluster_endpoint  = data.aws_eks_cluster.cluster-data.endpoint
  cluster_version   = data.aws_eks_cluster.cluster-data.version
  oidc_provider_arn = data.aws_iam_openid_connect_provider.this.arn

  enable_aws_load_balancer_controller = true

  observability_tag = null

  eks_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      configuration_values = jsonencode({
        controller = {
          podAnnotations = {
            "cluster-autoscaler.kubernetes.io/safe-to-evict" : "true"
          }
        }
      })
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    snapshot-controller = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
  }

  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  cluster_autoscaler = {
    chart_version = "9.43.2"
    atomic        = true
    reset_values  = true
    lint          = true
    # https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#values
    values = [
      yamlencode({
        extraArgs = {
          "max-graceful-termination-sec" : "1800" # 30 minutes
        }
        autoDiscovery = {
          tags = [
            "k8s.io/cluster-autoscaler/enabled=true",
            "k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}"
          ]
        },
        podAnnotations = {
          "cluster-autoscaler.kubernetes.io/safe-to-evict" : "true",
        }
      })
    ]
  }

  tags = var.tags
}

################################################################################
# GP3 default
################################################################################

resource "kubernetes_annotations" "gp2_default" {
  annotations = {
    "storageclass.kubernetes.io/is-default-class" : "false"
  }
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }

  force = true
}

resource "kubernetes_storage_class" "gp3_default" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" : "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    fsType    = "ext4"
    encrypted = true
    type      = "gp3"
  }

  depends_on = [
    kubernetes_annotations.gp2_default,
  ]
}

################################################################################
# EFS
################################################################################

module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.5"

  name = data.aws_eks_cluster.cluster-data.id
  encrypted = true

  performance_mode = "generalPurpose"
  throughput_mode = "elastic"

  create_backup_policy = false
  enable_backup_policy = false

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  mount_targets = { for i, r in var.private_subnet_ids : "mount_${i}" => {subnet_id : r } }

  create_security_group      = true
  security_group_description = "EFS security group for ${data.aws_eks_cluster.cluster-data.id} EKS cluster"
  security_group_vpc_id      = var.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = local.private_subnet_cidr_blocks
    }
  }

  tags = var.tags
}

resource "kubernetes_storage_class" "efs_etcd" {
  metadata {
    name = "efs-etcd"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  parameters = {
    basePath              = "/etcd"
    directoryPerms        = "700"
    ensureUniqueDirectory = "true"
    fileSystemId          = module.efs.id
    gidRangeEnd           = "2000"
    gidRangeStart         = "1000"
    provisioningMode      = "efs-ap"
    reuseAccessPoint      = "false"
    subPathPattern        = "$${.PVC.name}"
  }
}
