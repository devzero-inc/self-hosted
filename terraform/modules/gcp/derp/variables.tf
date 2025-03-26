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

variable "network" {
  type        = string
  description = "VPC Network Name"
}

variable "subnet" {
  type        = string
  description = "Subnet Name"
}

variable "instance_type" {
  type        = string
  description = "Compute Engine instance type"
  default     = "e2-medium"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 20
}

variable "public_derp" {
  type        = bool
  description = "Whether to assign a static public IP"
  default     = false
}

variable "hostname" {
  type        = string
  description = "Hostname for the instance"
  default     = ""
}

variable "ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect"
  default     = ["0.0.0.0/0"]
}