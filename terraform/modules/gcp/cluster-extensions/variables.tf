variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for resources"
}

variable "enable_filestore" {
  description = "Enable Filestore (EFS equivalent)"
  type        = bool
  default     = true
}
