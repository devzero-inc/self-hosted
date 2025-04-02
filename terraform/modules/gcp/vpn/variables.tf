variable "name" {
  description = "Prefix or name used for VPN resources"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "location" {
  description = "GCP zone where the VPN instance will be created"
  type        = string
}

variable "network" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet" {
  description = "Name of the subnet to attach VPN instance"
  type        = string
}

variable "vpn_client_list" {
  description = "List of client identifiers (used for generating client certs and ovpn files)"
  type        = set(string)
}

variable "bucket_location" {
  description = "Location of the GCS bucket for storing OVPN files"
  type        = string
}

variable "machine_type" {
  description = "GCE instance machine type for OpenVPN server"
  type        = string
  default     = "e2-medium"
}

variable "boot_image" {
  description = "Image to use for the VPN server instance (e.g. ubuntu-2004 image)"
  type        = string
}

variable "additional_server_dns_names" {
  description = "Additional DNS SANs for the server certificate"
  type        = list(string)
  default     = []
}

variable "devzero_service_account" {
  description = "IAM service account email used by Vault for unsealing"
  type        = string
}
