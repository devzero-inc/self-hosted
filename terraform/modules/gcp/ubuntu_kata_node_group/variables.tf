variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "zone" {
  type        = string
  description = "GCP Zone"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster Name"
}

variable "instance_type" {
  type        = string
  description = "GCE instance type"
  default     = "e2-standard-4"
}

variable "disk_size" {
  type        = number
  description = "Node disk size in GB"
  default     = 100
}

variable "min_size" {
  type        = number
  description = "Minimum number of nodes"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of nodes"
  default     = 4
}
