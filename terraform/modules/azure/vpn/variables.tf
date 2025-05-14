variable "tenant_id" {}
variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "gateway_subnet_id" {}
variable "vpn_client_cidr" {
  default = "172.16.0.0/24"
}

variable "vpn_gateway_port" {
  description = "The port for the VPN gateway"
  type        = string
  default     = "1194"
}
variable "vpn_client_list" {
  type = set(string)
}

variable "sp_object_id" {}