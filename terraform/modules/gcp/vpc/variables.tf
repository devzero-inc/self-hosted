variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "prefix" {
  type        = string
  description = "Resource Prefix"
}

variable "subnets" {
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_range = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  description = "List of subnets"
}

