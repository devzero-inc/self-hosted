locals {
  azs = (var.availability_zones_count > 0) ? slice(data.aws_availability_zones.available.names, 0, min(var.availability_zones_count, length(data.aws_availability_zones.available.names))) : var.availability_zones

  calculated_public_subnets_ids = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : module.vpc.public_subnets
  calculated_private_subnets_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : module.vpc.private_subnets
  calculated_security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [module.vpc.default_security_group_id]

  vpc_id = var.create_vpc ? module.vpc.vpc_id : var.vpc_id

  calculated_public_subnets_cidrs = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  calculated_private_subnets_cidrs = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k + 6)]

  private_subnet_cidr_blocks = var.create_vpc ? module.vpc.private_subnets_cidr_blocks : [for subnet in data.aws_subnet.private_subnets : subnet.cidr_block]

  public_subnet_cidr_blocks = var.create_vpc ? module.vpc.public_subnets_cidr_blocks : [for subnet in data.aws_subnet.public_subnets : subnet.cidr_block]

  effective_zone_id = var.use_existing_route53_zone ? var.existing_zone_id : aws_route53_zone.private[0].zone_id

  effective_vpc_cidr_block = var.create_vpc ? module.vpc.vpc_cidr_block : data.aws_vpc.existing[0].cidr_block

  vpc_dns_resolver = cidrhost(var.cidr, 2) # Calculates the +2 host of the CIDR for VPN DNS resolving

  static_node_groups = {
    "node_group_1" = module.eks.eks_managed_node_groups["${var.name}-nodes"].node_group_autoscaling_group_names[0]
  }
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
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster-data.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster-auth.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
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
data "aws_subnet" "private_subnets" {
  for_each = var.create_vpc ? toset([]) : toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public_subnets" {
  for_each = var.create_vpc ? toset([]) : toset(var.public_subnet_ids)
  id       = each.value
}

data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

module "vpc" {
  depends_on = [
    null_resource.validations
  ]
  create_vpc = var.create_vpc

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "${var.name}-vpc"
  cidr = var.cidr

  # subnets
  azs             = local.azs
  public_subnets  = local.calculated_public_subnets_cidrs
  private_subnets = local.calculated_private_subnets_cidrs

  public_subnet_tags  = var.additional_public_subnet_tags
  private_subnet_tags = var.additional_private_subnet_tags

  # network acl
  manage_default_network_acl = var.manage_default_network_acl

  # nat gateways
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  propagate_private_route_tables_vgw = false
  propagate_public_route_tables_vgw  = false

  # internet gateway
  create_igw       = var.create_igw
  instance_tenancy = var.instance_tenancy

  # enable vpn gateway
  enable_vpn_gateway = var.create_vpn

  enable_dns_hostnames = true
  enable_dns_support = true
  enable_dhcp_options = true

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

  tags = var.tags
}

################################################################################
# EKS
################################################################################
data "aws_ami" "ubuntu-eks_1_30" {
  name_regex  = "ubuntu-eks/k8s_1.30/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  most_recent = true
  owners      = ["099720109477"]
}

#module "node_cluster_role" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#  version = "5.51.0"
#
#  trusted_role_services = [
#    "ec2.amazonaws.com",
#  ]
#  trusted_role_actions = [
#    "sts:AssumeRole",
#  ]
#
#  create_role       = true
#  role_name_prefix  = "${substr(var.cluster_name,0 ,(38-length(var.node_role_suffix)))}${var.node_role_suffix}"
#  role_description  = "EKS managed node group IAM role"
#  role_requires_mfa = false
#
#  force_detach_policies = true
#
#  custom_role_policy_arns = [
#    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
#    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
#    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
#  ]
#}

data "aws_iam_roles" "sso_awsadministratoraccess" {
  name_regex = "AWSReservedSSO_AWSAdministratorAccess.*"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = "${var.name}-cluster"
  cluster_version = var.cluster_version

  # Use the provided VPC ID directly if create_vpc is false
  vpc_id = local.vpc_id

  subnet_ids = local.calculated_private_subnets_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []
  cluster_endpoint_private_access      = true # TODO: we should check this a bit more, private should always be enabled? 

  kms_key_administrators = concat(
    var.kms_key_administrators, 
    [
      one(data.aws_iam_roles.sso_awsadministratoraccess.arns)
    ]
  )

  kms_key_aliases               = ["${var.name}-cluster"]
  kms_key_enable_default_policy = var.kms_key_enable_default_policy

  eks_managed_node_groups = {
    "${var.name}-nodes" = {
      name           = "${var.name}-nodes"
      instance_types = [var.worker_instance_type]
      key_name       = var.nodes_key_name

      ami_id = data.aws_ami.ubuntu-eks_1_30.image_id

      min_size     = var.desired_node_size
      max_size     = var.max_node_size
      desired_size = var.desired_node_size

      enable_bootstrap_user_data = true
      bootstrap_extra_args       = "--kubelet-extra-args '--runtime-request-timeout=\"15m\"'"

      block_device_mappings = {
        sda = {
          device_name = "/dev/sda1"
          ebs = {
            delete_on_termination = true
            encrypted             = true
            volume_size           = 500
            volume_type           = "gp3"
          }
        }
      }

      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  cluster_identity_providers = var.cluster_identity_providers

  # aws-auth configmap
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = var.eks_access_entries

  tags = var.tags
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
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

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
    module.eks,
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
  security_group_vpc_id      = local.vpc_id
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

  depends_on = [
    module.eks,
  ]
}

################################################################################
# Ingress configuration
################################################################################

resource "aws_route53_zone" "private" {
  count = var.use_existing_route53_zone ? 0 : 1

  name = var.domain
  vpc {
    vpc_id = local.vpc_id
  }

  tags = var.tags
}

################################################################################
# VPN
################################################################################

module "vpn" {
  count = var.create_vpn ? 1 : 0

  source = "../../../modules/aws/vpn"

  name                          = var.name
  region                        = var.region
  additional_security_group_ids = [module.eks.cluster_primary_security_group_id]
  vpc_id                        = local.vpc_id
  subnet_ids                    = local.calculated_private_subnets_ids
  client_vpn_cidr_block         = var.client_vpn_cidr_block
  vpc_dns_resolver              = local.vpc_dns_resolver

  vpn_client_list               = var.vpn_client_list

  additional_server_dns_names = [
    "${var.domain}",
    "*.${var.domain}"
  ]
}

################################################################################
# Example of using custom ALB, and pointing it to the cluster node port
################################################################################

module "alb" {
  source = "../../../modules/aws/alb"

  name               = "${var.name}-backend"

  node_group_asg_names = local.static_node_groups

  additional_security_group_ids = [module.eks.node_security_group_id]
  vpc_id                        = local.vpc_id
  subnet_ids                    = local.calculated_private_subnets_ids
  vpc_cidr                      = local.effective_vpc_cidr_block
  certificate_arn               = module.vpn[0].vpn_server_certificate_arn
  target_port                   = 30080
  record                        = "backend.${var.domain}"
  zone_id                       = local.effective_zone_id
  health_check = {
    enabled             = true
    path                = "/"       
    interval            = 30     
    timeout             = 5        
    healthy_threshold   = 2       
    unhealthy_threshold = 2          
    matcher             = "200"     
  }

  depends_on = [
    module.vpn,
    module.eks
  ]
}
