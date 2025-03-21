variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "gke_subnet_cidr" {
  description = "CIDR block for the GKE subnet"
  type        = string
}

variable "mtu" {
  description = "MTU for the network"
  type        = number
  default     = 1460
}

variable "create_vpc" {
  description = "Whether to create a VPC"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes in GKE"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint in GKE"
  type        = bool
  default     = false
}

variable "gke_master_version" {
  description = "Kubernetes master version"
  type        = string
}

variable "gke_cluster_location" {
  description = "The primary zone where the GKE cluster will be created (single-zone setup)."
  type        = string
}

variable "gke_zones" {
  description = "List of zones for the GKE cluster (for a single-zone cluster, provide one zone)."
  type        = list(string)
}
