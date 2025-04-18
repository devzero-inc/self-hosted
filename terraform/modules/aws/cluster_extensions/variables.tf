################################################################################
# Common
################################################################################
variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
  validation {
    condition     = length(var.cluster_name) < 39
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
# EKS Blueprints Addons
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = false
}

variable "enable_external_secrets" {
  description = "Enable External Secrets operator add-on"
  type        = bool
  default     = false
}

variable "max_volumes_per_node" {
  description = "Maximum number of volumes per node"
  type        = number
  default     = 23
}

################################################################################
# EFS
################################################################################

variable "enable_efs" {
  description = "Enable EFS"
  type        = bool
  default     = true
}
