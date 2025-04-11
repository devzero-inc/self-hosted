variable "cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "region" {
  type = string
  description = "The AWS region where the EKS cluster is deployed"
}