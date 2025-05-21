variable "cluster_name" {
  description = "Cluster name used in naming NAT resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy NAT resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to associate with route table"
  type        = list(string)
}
