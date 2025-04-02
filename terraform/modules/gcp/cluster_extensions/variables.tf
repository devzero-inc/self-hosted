variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "location" {
  type        = string
  description = "GCP location for resources"
}

variable "tags" {
  type    = map(string)
}

variable "enable_pd_csi_driver" {
  type    = bool
  default = true
}

variable "enable_cluster_autoscaler" {
  type    = bool
  default = true
}

variable "cluster_autoscaler_chart_version" {
  type    = string
  default = "9.43.2"
}

variable "disable_existing_default_storage_class" {
  type    = bool
  default = true
}

variable "previous_default_storage_class_name" {
  type    = string
  default = "standard"
}

variable "enable_filestore" {
  type    = bool
  default = false
}
variable "efs_capacity_gb" {
  type    = number
  default = 1024
}
variable "filestore_reserved_ip_range" {
  type    = string
  default = "10.10.0.0/29"
}
variable "vpc_name" {
  type = string
}
