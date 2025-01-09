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


################################################################################
# EKS
################################################################################
variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Cluster environment"
}

variable "worker_instance_type" {
  type        = string
  description = "Node instance type"
}

variable "desired_node_size" {
  type        = number
  description = "Desired node size"
}

variable "max_node_size" {
  type        = number
  description = "Max node size"
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


################################################################################
# EKS Blueprints Addons
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type = bool
  default = false
}