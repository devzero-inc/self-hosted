################################################################################
# Common
################################################################################
variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
  validation {
    condition = length(var.cluster_name) < 39
    error_message = "The name must be less than 39 characters"
  }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "vpc_id" {
  description = "The ID of the VPC that the cluster will be deployed in"
  type        = string
  default = null
  validation {
    condition = (var.vpc_id != null && can(startswith(var.vpc_id, "vpc-")) || var.vpc_id == null)
    error_message = "AWS VPC ids must start with `vpc-`"
  }
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
  description = "Private subnets."
  type        = list(string)
  default = []
  validation {
    condition = alltrue([for subnet in var.private_subnet_ids : startswith(subnet, "subnet-")])
    error_message = "AWS subnets ids must start with `subnet-`"
  }
}
################################################################################
# EKS Blueprints Addons
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type = bool
  default = false
}
