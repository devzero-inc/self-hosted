variable "region" {
  type        = string
  description = "AWS region"
  default = "us-west-1"
}

variable "worker_instance_type" {
  type        = string
  description = "Node instance type"
  default = "m5.4xlarge"
}

variable "nodes_key_name" {
  description = "Nodes Kay Pair name"
  default     = ""
}

variable "node_role_suffix" {
  default = "-nodes-eks-ubuntu-"
  description = "Suffix to use on the node group IAM role"
}
