variable "cluster_name" {}
variable "resource_group_name" {}
variable "location" {}
variable "enable_external_secrets" {
  type    = bool
  default = false
}
variable "enable_azure_files" {
  type    = bool
  default = false
}
variable "tags" {
  type = map(string)
  default = {}
}