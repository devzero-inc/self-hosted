variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for subnets"
}

variable "mtu" {
  type        = number
  description = "MTU for the VPC"
}

variable "gke_subnet_cidr" {
  type        = string
  description = "CIDR for GKE subnet"
}

variable "prefix" {
  type        = string
  description = "Name prefix for resources"
}

variable "subnet_name" {
  type        = string
  description = "Name of the GKE subnet"
}

variable "pods_range_name" {
  type        = string
  description = "Secondary range name for pods"
}

variable "services_range_name" {
  type        = string
  description = "Secondary range name for services"
}

variable "pods_secondary_range_cidr" {
  type        = string
  description = "CIDR block for the secondary range used by pods"
}

variable "services_secondary_range_cidr" {
  type        = string
  description = "CIDR block for the secondary range used by services"
}
