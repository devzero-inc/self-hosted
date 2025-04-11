variable "cluster_name" {
  type = string
}

variable "cluster_host" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "domain" {
  type = string
}

variable "region" {
  type = string
  description = "The AWS region where the EKS cluster is deployed"
}

variable "chart_prefix" {
  type = string
  default = "devzero-control-plane"
}