locals {
  azs = (var.availability_zones_count > 0) ? slice(data.aws_availability_zones.available.names, 0, min(var.availability_zones_count, length(data.aws_availability_zones.available.names))) : var.availability_zones

  calculated_public_subnets_ids  = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : module.vpc.public_subnets
  calculated_private_subnets_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : module.vpc.private_subnets
  calculated_security_group_ids  = length(var.security_group_ids) > 0 ? var.security_group_ids : [module.vpc.default_security_group_id]

  vpc_id = var.create_vpc ? module.vpc.vpc_id : var.vpc_id

  calculated_public_subnets_cidrs  = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  calculated_private_subnets_cidrs = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k + 6)]

  private_subnet_cidr_blocks = var.create_vpc ? module.vpc.private_subnets_cidr_blocks : [for subnet in data.aws_subnet.private_subnets : subnet.cidr_block]

  public_subnet_cidr_blocks = var.create_vpc ? module.vpc.public_subnets_cidr_blocks : [for subnet in data.aws_subnet.public_subnets : subnet.cidr_block]

  effective_zone_id = var.use_existing_route53_zone ? var.existing_zone_id : aws_route53_zone.private[0].zone_id

  effective_vpc_cidr_block = var.create_vpc ? module.vpc.vpc_cidr_block : data.aws_vpc.existing[0].cidr_block

  vpc_dns_resolver = cidrhost(local.effective_vpc_cidr_block, 2)
  # Calculates the +2 host of the CIDR for VPN DNS resolving

}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {
  count = var.add_current_user_to_kms ? 1 : 0
}

data "aws_iam_session_context" "current" {
  count = var.add_current_user_to_kms ? 1 : 0

  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = try(data.aws_caller_identity.current[0].arn, "")
}

# terraform {
#   backend "s3" {
#       bucket         	   = "dsh-tf-state"
#       key              	   = "base-cluster/terraform.tfstate"
#       region         	   = "us-west-1"
#   }
# }

################################################################################
# Providers
################################################################################

provider "tls" {}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      CreatedBy: "DevZero"
    }
  }
}

data "aws_eks_cluster" "cluster-data" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name       = module.eks.cluster_name
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

  name = "${var.cluster_name}-vpc"
  cidr = var.cidr

  # subnets
  azs             = local.azs
  public_subnets  = local.calculated_public_subnets_cidrs
  private_subnets = local.calculated_private_subnets_cidrs

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # nat gateways
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # internet gateway
  create_igw = var.create_igw

  # enable vpn gateway
  enable_vpn_gateway = var.create_vpn

  enable_dhcp_options = var.enable_dhcp_options

  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  default_security_group_ingress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = join(",", local.calculated_private_subnets_cidrs)
    }
  ]

  tags = var.tags
}

################################################################################
# EKS
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Use the provided VPC ID directly if create_vpc is false
  vpc_id = local.vpc_id

  subnet_ids = local.calculated_private_subnets_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []

  # We always enable private access by default.
  cluster_endpoint_private_access = true

  cluster_additional_security_group_ids = var.security_group_ids

  cluster_enabled_log_types = [
    "audit", "api", "authenticator", "controllerManager", "scheduler"
  ]

  kms_key_administrators = concat(
    var.kms_key_administrators,
    [
      try(data.aws_iam_session_context.current[0].issuer_arn, "")
    ]
  )

  # Cluster IAM role
  create_iam_role = true
  # Hack to help fixing length the name of the iam role for long named clusters
  iam_role_name = "${substr(var.cluster_name, 0, (37 - length("-cluster")))}-cluster"


  kms_key_aliases               = [var.cluster_name]
  kms_key_enable_default_policy = var.kms_key_enable_default_policy

  cluster_identity_providers = var.cluster_identity_providers

  # aws-auth configmap
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = var.eks_access_entries

  tags = var.tags
}

data "aws_ami" "devzero_amazon_eks_node_al2023" {
  filter {
    name   = "name"
    values = ["devzero-amazon-eks-node-al2023-x86_64-standard-${var.cluster_version}-*"]
  }
  owners      = ["710271940431"] # Devzero public AMIs account
  most_recent = true
}

module "kata_node_group" {
  source = "../../../modules/aws/kata_node_group"

  count = var.enable_kata_node_group ? 1 : 0

  cluster_name = module.eks.cluster_name

  instance_type = var.instance_type

  ami_id = data.aws_ami.devzero_amazon_eks_node_al2023.image_id

  # Optinally pass in CA certificate
  enable_custom_ca_cert = var.create_vpn
  custom_ca_cert = var.create_vpn ? module.vpn[0].vpn_ca_certificate : ""

  desired_size = var.desired_size
  min_size     = var.min_size
  max_size     = var.max_size

  depends_on = [
    module.eks
  ]
}


################################################################################
# VPN
################################################################################

module "vpn" {
  count = var.create_vpn ? 1 : 0

  source = "../../../modules/aws/vpn"

  name                          = var.cluster_name
  region                        = var.region
  additional_security_group_ids = [module.eks.cluster_primary_security_group_id]
  vpc_id                        = local.vpc_id
  subnet_ids                    = local.calculated_private_subnets_ids
  client_vpn_cidr_block         = var.client_vpn_cidr_block
  vpc_dns_resolver              = local.vpc_dns_resolver

  vpn_client_list = var.vpn_client_list

  additional_server_dns_names = [
    "${var.domain}",
    "*.${var.domain}"
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
# Example of using custom DERP server
################################################################################
module "derp" {
  source = "../../../modules/aws/derp"

  count  = var.create_derp ? 1 : 0

  vpc_id = local.vpc_id
  subnet_id = local.calculated_private_subnets_ids[0]
}

################################################################################
# Example of using custom ALB, and pointing it to the cluster node port
################################################################################
module "alb" {
  source = "../../../modules/aws/alb"
  count  = var.create_alb ? 1 : 0

  name = "${substr(var.cluster_name, 0, (32 - length("-service")))}-service"

  node_group_asg_names = merge({
    # Other ASG names to be added to this ALB
    },
    # If ubuntu node group is enabled, add it to the ALB
    var.enable_kata_node_group ? {
      "kata_node_group" = module.kata_node_group[0].node_group.node_group_autoscaling_group_names[0]
    } : {}
  )

  additional_security_group_ids = [module.eks.node_security_group_id]
  vpc_id                        = local.vpc_id
  subnet_ids                    = local.calculated_private_subnets_ids
  vpc_cidr                      = local.effective_vpc_cidr_block
  certificate_arn               = var.create_vpn ? module.vpn[0].vpn_server_certificate_arn : null
  target_port                   = 30080
  record                        = "service.${var.domain}"
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
    module.eks
  ]
}

################################################################################
# Vault Auto-Unseal Key
################################################################################
resource "aws_kms_key" "vault-auto-unseal" {
  count = var.create_vault_auto_unseal_key ? 1 : 0
  description = "Vault auto unseal keys"

  deletion_window_in_days = 10
}
resource "aws_kms_alias" "vault-auto-unseal" {
  count = var.create_vault_auto_unseal_key ? 1 : 0

  name          = "alias/${var.cluster_name}-auto-unseal"
  target_key_id = aws_kms_key.vault-auto-unseal[0].key_id
}

resource "aws_kms_key_policy" "vault-auto-unseal" {
  count = var.create_vault_auto_unseal_key ? 1 : 0

  key_id = aws_kms_key.vault-auto-unseal[0].id
  policy = jsonencode({
    Id = "${var.cluster_name}-auto-unseal"
    Statement = [
      {
        Action = [
          "kms:*",
        ]
        Effect = "Allow"
        Principal = {
          # Uncomment this to allow only current terraform user to manage the KMS key
          # AWS = data.aws_iam_session_context.current[0].issuer_arn

          # Allows everyone with KMS access to manage this key
          AWS = "*"
        }
        Resource = "*"
        Sid      = "Vault unseal key management for cluster: (${var.cluster_name})"
      },
      {
        "Sid": "KeyUsage",
        "Effect": "Allow",
        "Principal": {
          "AWS": module.eks.cluster_iam_role_arn
        },
        "Action": [
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:Decrypt"
        ],
        "Resource": "*"
      }
    ]
    Version = "2012-10-17"
  })
}
