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
# EKS Blueprints Addons
################################################################################

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler"
  type = bool
  default = false
}

variable "enable_external_secrets" {
  description = "Enable external secrets"
  type = bool
  default = false
}
