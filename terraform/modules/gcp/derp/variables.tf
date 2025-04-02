variable "public_derp" {}
variable "existing_ip" { default = "" }
variable "name_prefix" {}
variable "hostname" {}
variable "region" {}
variable "zone" {}
variable "network" {}
variable "subnetwork" {}
variable "instance_type" { default = "e2-medium" }
variable "volume_size" { default = 20 }
variable "tags" { type = map(string) }
variable "ingress_cidr_blocks" { type = list(string) }
variable "firewall_rule_name" { default = "" }
variable "service_account_email" {}

variable "ubuntu_family" {
  default = "ubuntu-2204-lts"
}