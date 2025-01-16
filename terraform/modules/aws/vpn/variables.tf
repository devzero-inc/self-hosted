variable "name" {
  type        = string
  description = "Name of the ALB"
}

variable "region" {
  type        = string
  description = "Region name"
}

variable "additional_security_group_ids" {
  description = "VPC security groups to allow connection from/to vpn"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  type    = string
  description = "VPC ID to associate with the Client VPN endpoint"
}

variable "subnet_ids" {
  description = "Subnet IDs to associate with the Client VPN endpoint"
  type        = list(string)
  default     = []
}

variable "client_vpn_cidr_block" {
  type    = string
  default = "10.9.0.0/22"
  description = "CIDR for Client VPN IP addresses"
}

variable "vpc_dns_resolver" {
  type    = string
  description = "CIDR for VPC DNS resolver"
}

variable "additional_routes" {
  description = "Additional Routes"
  type        = list(map(string))
  default     = []
}

variable "vpn_client_list" {
  description = "VPN client list, we need to always keep root user to login to the VPN"
  type        = set(string)
  default     = ["root"]
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_server_dns_names" {
  description = "Additional DNS names for the server certificate"
  type        = list(string)
  default     = []
}
