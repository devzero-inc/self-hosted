################################################################################
# Common
################################################################################
variable "region" {
  type        = string
  description = "AWS region"
}

variable "name" {
  type        = string
  description = "Name prefix to be used by resources"
  default     = "devzero"
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
  default = null
  validation {
    condition = (var.vpc_id != null && can(startswith(var.vpc_id, "vpc-")) || var.vpc_id == null)
    error_message = "AWS VPC ids must start with `vpc-`"
  }
}

variable "cidr" {
  type        = string
  description = "Cidr block"
  default = null
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
  default = []
  validation {
    condition = alltrue([for subnet in var.public_subnet_ids : startswith(subnet, "subnet-")])
    error_message = "AWS subnets ids must start with `subnet-`"
  }
}

variable "private_subnet_ids" {
  description = "Private subnets. Required if create_vpc is false"
  type        = list(string)
  default = []
  validation {
    condition = alltrue([for subnet in var.private_subnet_ids : startswith(subnet, "subnet-")])
    error_message = "AWS subnets ids must start with `subnet-`"
  }
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "additional_public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "additional_private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
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

variable "manage_default_network_acl" {
  description = "Should be true to adopt and manage Default Network ACL"
  type        = bool
  default     = true
}
