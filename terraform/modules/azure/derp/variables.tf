variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
  description = "Use subnet ID from the shared VNet module"
}

variable "firewall_rule_name" {
  type    = string
  default = ""
}

variable "public_derp" {
  type = bool
}

variable "existing_ip" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type = string
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "hostname" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vm_size" {
  type = string
}

variable "volume_size" {
  type = number
}
