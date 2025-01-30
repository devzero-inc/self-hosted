################################################################################
# Common
################################################################################
variable "cluster_name" {
  type        = string
  description = "Name prefix to be used by resources"
  default     = "devzero"
  validation {
    condition     = length(var.cluster_name) < 39
    error_message = "The name must be less than 39 characters. Current length is ${length(var.cluster_name)} characters."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
}

variable "vpc_id" {
  description = "The ID of the VPC that the cluster will be deployed in (required if create_vpc is false)"
  type        = string
  default     = null
  validation {
    condition     = (var.vpc_id != null && can(startswith(var.vpc_id, "vpc-")) || var.vpc_id == null)
    error_message = "AWS VPC ids must start with `vpc-`"
  }
}

variable "cidr" {
  type        = string
  description = "Cidr block"
  default     = null
}

variable "availability_zones_count" {
  description = "The number of availability zones available for the VPC and EKS cluster"
  type        = number
  default     = 0
}

variable "availability_zones" {
  description = "Availability zones. Required if availability_zones_count is not set"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Public subnets. Optionally create public subnets"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for subnet in var.public_subnet_ids : startswith(subnet, "subnet-")])
    error_message = "AWS subnets ids must start with `subnet-`"
  }
}

variable "private_subnet_ids" {
  description = "Private subnets. Required if create_vpc is false"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for subnet in var.private_subnet_ids : startswith(subnet, "subnet-")])
    error_message = "AWS subnets ids must start with `subnet-`"
  }
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone."
  type        = bool
  default     = true
}

variable "enable_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type"
  default     = true
}

################################################################################
# VPN
################################################################################

variable "create_vpn" {
  description = "Controls if VPN gateway and VPN resources will be created."
  type        = bool
  default     = false
}

variable "additional_routes" {
  description = "Additional Routes"
  type        = list(map(string))
  default     = []
}

variable "client_vpn_cidr_block" {
  type        = string
  default     = "10.9.0.0/22"
  description = "CIDR for Client VPN IP addresses"
}

variable "vpn_client_list" {
  description = "Subnets"
  type        = set(string)
  default     = ["root"]
}


################################################################################
# Routes
################################################################################
variable "domain" {
  type        = string
  description = "Name of the private domain"
}

variable "use_existing_route53_zone" {
  type        = bool
  default     = true
  description = "If true, skip creating a new Route53 zone and use an existing zone_id instead"
}

variable "existing_zone_id" {
  type        = string
  default     = null
  description = "The existing Route53 zone ID (if use_existing_route53_zone is true)"
}

################################################################################
# EKS
################################################################################
variable "cluster_version" {
  type        = string
  description = "Cluster version to use for EKS deployment"
  default     = "1.30"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "subnet_ids" {
  description = "Subnets"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "VPC security groups to allow connection from/to cluster"
  type        = list(string)
  default     = []
}

variable "disk_size" {
  description = "Nodes disk size in GiB"
  type        = number
  default     = 200
}

variable "kms_key_enable_default_policy" {
  description = "Enable default KMS key policy"
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}

variable "cluster_identity_providers" {
  description = "Optional list of cluster identity providers"
  default     = {}
}

variable "eks_access_entries" {
  description = "EKS Access entries"
  default     = {}
}

variable "cluster_endpoint_public_access" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  default     = null
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}

variable "node_role_suffix" {
  default     = "-nodes-eks-node-group-"
  description = "Suffix to use on the node group IAM role"
}

variable "add_current_user_to_kms" {
  description = "Adds the current terraform user as an admin of EKS KMS key"
  type        = bool
  default     = true
}

variable "min_size" {
  type        = number
  description = "Min node size"
  default     = 1
}

variable "desired_size" {
  type        = number
  description = "Desired node size"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Max node size"
  default     = 4
}

variable "instance_type" {
  type        = string
  description = "Node instance type"
  default     = "m5.4xlarge"
}


variable "enable_kata_node_group" {
  description = "Enable kata node groups"
  type        = bool
  default     = true
}

################################################################################
# Vault
################################################################################
variable "create_vault_auto_unseal_key" {
  description = "Whether or not to create a KMS key for Vault auto unseal"
  type = bool
  default = false
}

################################################################################
# Example of using custom DERP server
################################################################################
variable "create_derp" {
  description = "Create custom DERP server"
  type        = bool
  default     = false
}

################################################################################
# Example of using custom ALB, and pointing it to the cluster node port
################################################################################
variable "create_alb" {
  description = "Create custom ALB pointing to the cluster node port"
  type        = bool
  default     = false
}
