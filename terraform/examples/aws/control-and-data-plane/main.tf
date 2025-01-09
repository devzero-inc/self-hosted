locals {
  azs = (var.availability_zones_count > 0) ? slice(data.aws_availability_zones.available.names, 0, min(var.availability_zones_count, length(data.aws_availability_zones.available.names))) : var.availability_zones

  calculated_public_subnets_ids = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : module.vpc.public_subnets
  calculated_private_subnets_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : module.vpc.private_subnets
  calculated_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [module.vpc.default_security_group_id]

  calculated_public_subnets_cidrs = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  calculated_private_subnets_cidrs = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k + 6)]
}

data "aws_availability_zones" "available" {}

################################################################################
# Providers
################################################################################

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster-data" {
  name = module.eks.name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name = module.eks.name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = module.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-data.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster-auth.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-data.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster-auth.token
  }
}


################################################################################
# Common resources
################################################################################

resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = !(var.create_vpc == true && var.availability_zones_count == 0 && length(var.availability_zones) == 0)
      error_message = "The variable availability_zones_count must be set if availability_zones is not set"
    }

    precondition {
      condition     = !(var.create_vpc == true && var.cidr == null)
      error_message = "The variable cidr must be set if create_vpc is false. This is the cidr range used to create the VPC"
    }

    precondition {
      condition     = !(var.create_vpc == false && var.vpc_id == null)
      error_message = "The variable vpc_id must be set if create_vpc is false"
    }

    precondition {
      condition     = !(var.create_vpc == false && length(var.private_subnet_ids) == 0)
      error_message = "The variable private_subnets must be set if create_vpc is false"
    }

    precondition {
      condition     = !(var.create_vpc == false && length(var.public_subnet_ids) == 0)
      error_message = "The variable public_subnets must be set if create_vpc is false"
    }

    precondition {
      condition     = !(var.create_vpc == false && length(var.security_group_ids) == 0)
      error_message = "The variable security_group_ids must be set if create_vpc is false"
    }
  }
}

################################################################################
# VPC
################################################################################
module "vpc" {
  depends_on = [
    null_resource.validations
  ]
  create_vpc = var.create_vpc

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "devzero-${terraform.workspace}-${random_string.this.result}"
  cidr = var.cidr

  azs             = local.azs
  public_subnets  = local.calculated_public_subnets_cidrs
  private_subnets = local.calculated_private_subnets_cidrs


  manage_default_network_acl = true

  enable_nat_gateway = true
  single_nat_gateway = true

  default_security_group_egress = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  default_security_group_ingress = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = join(",", local.calculated_private_subnets_cidrs)
    }
  ]
}

################################################################################
# EKS
################################################################################
# data "aws_iam_roles" "sso_awsadministratoraccess" {
#   name_regex = "AWSReservedSSO_AWSAdministratorAccess.*"
# }

module "eks" {
  source = "../../../modules/aws/eks"

  cluster_name = "devzero-${terraform.workspace}-${random_string.this.result}"

  region               = var.region
  environment          = var.environment
  security_group_ids   = local.calculated_security_group_ids
  subnet_ids           = local.calculated_private_subnets_ids
  desired_node_size    = var.desired_node_size
  max_node_size        = var.max_node_size
  min_node_size        = var.desired_node_size
  worker_instance_type = var.worker_instance_type

  # EKS access entries. Uncomment this block to add access entries to the EKS cluster
  # access_entries      =  {
  #   # Adds the AWSAdministratorAccess policy to the SSO user or other principal Role
  #   admins = {
  #     kubernetes_groups = []
  #     # The role to get Admin access to this cluster
  #     principal_arn     = one(data.aws_iam_roles.sso_awsadministratoraccess.arns)
  #     policy_associations = {
  #       admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }
}

# Data source to get the AWS account ID
data "aws_caller_identity" "current" {}


################################################################################
# EKS Blueprints Addons
################################################################################
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.51.0"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true
  policy_name_prefix    = module.eks.cluster_name

  oidc_providers = {
    main = {
      provider_arn               = module.eks.provider_id
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}


module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"

  cluster_name      = module.eks.name
  cluster_endpoint  = module.eks.endpoint
  cluster_version   = module.eks.version
  oidc_provider_arn = module.eks.provider_id

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

  depends_on = [
    module.eks,
  ]
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
  depends_on = [
    module.vpc,
  ]
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.5"

  name = module.eks.cluster_name
  encrypted = true

  performance_mode = "generalPurpose"
  throughput_mode = "elastic"

  create_backup_policy = false
  enable_backup_policy = false

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  mount_targets = { for i, r in local.calculated_private_subnets_ids : "mount_${i}" => {subnet_id : r } }

  create_security_group      = true
  security_group_description = "EFS security group for ${module.eks.cluster_name} EKS cluster"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }
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

  depends_on = [
    module.eks,
  ]
}
