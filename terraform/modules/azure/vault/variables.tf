variable "cluster_name" {
  description = "The name of the AKS or Vault cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "service_principal_object_id" {
  description = "Object ID of the service principal to assign key access to"
  type        = string
}
