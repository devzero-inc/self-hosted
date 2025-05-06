variable "resource_group_name" {
  description = "Name of the resource group in which resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region where the resources will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the virtual network"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether the AKS API server should be publicly accessible"
  type        = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs allowed to access the API server if public access is enabled"
  type        = list(string)
  default     = []
}

variable "enable_rbac" {
  type    = bool
}

variable "enable_private_cluster" {
  type    = bool
}

variable "admin_group_object_ids" {
  description = "List of AAD group object IDs with admin access to the cluster"
  type        = list(string)
}

variable "instance_type" {
  description = "VM size for the default node pool"
  type        = string
}

variable "enable_cluster_autoscaler" {
  type    = bool
}


variable "node_count" {
  type    = number
}

variable "min_size" {
  description = "Minimum number of nodes in the default node pool"
  type        = number
}

variable "max_size" {
  description = "Maximum number of nodes in the default node pool"
  type        = number
}

variable "desired_size" {
  description = "Desired number of nodes in the default node pool (ignored when autoscaling is enabled)"
  type        = number
  default     = null
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateway"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway for all subnets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 

################################################################################
# Custom DERP server
################################################################################
variable "create_derp" {
  description = "Create custom DERP server"
  type        = bool
  default     = false
}

variable "public_derp" {
  type        = bool
  default     = false
  description = "Whether to make the DERP server public"
}

################################################################################
# Vault
################################################################################
variable "create_vault_auto_unseal_key" {
  description = "Whether or not to create a KMS key for Vault auto unseal"
  type = bool
  default = false
}