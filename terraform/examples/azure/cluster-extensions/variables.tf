variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group containing the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
}

variable "enable_external_secrets" {
  description = "Whether to deploy the External Secrets Operator."
  type        = bool
  default     = false
}

variable "enable_azure_files" {
  description = "Whether to enable and set up the Azure Files CSI driver with default StorageClass."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
