variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "network" {
  type        = string
  description = "GCP VPC Network"
}

variable "peer_ip" {
  type        = string
  description = "External IP of the peer VPN gateway"
}

variable "vpn_shared_secret" {
  type        = string
  description = "Shared secret for VPN authentication"
}

variable "allowed_ip_range" {
  type        = string
  description = "Allowed IP range for VPN connection"
}

variable "name" {
  type        = string
  description = "VPN setup name"
}

variable "pem_private_key" {
  description = "The private key file for VPN"
  type        = string
  default     = null
}

variable "pem_certificate" {
  description = "The certificate file for VPN"
  type        = string
  default     = null
}
