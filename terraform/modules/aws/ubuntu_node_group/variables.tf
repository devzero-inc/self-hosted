variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-1"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
}

variable "instance_type" {
  type        = string
  description = "Node instance type"
  default     = "m5.4xlarge"
}

variable "nodes_key_name" {
  description = "Nodes Kay Pair name"
  default     = ""
}

variable "node_group_suffix" {
  description = "Suffix to use on the node group name"
  default     = "-ubuntu-nodes"
}

variable "node_role_suffix" {
  description = "Suffix to use on the node group IAM role"
  default     = "-nodes-eks-ubuntu-"
}

variable "min_size" {
  type        = number
  description = "Min node size"
  default     = 4
}

variable "desired_size" {
  type        = number
  description = "Desired node size"
  default     = 4
}

variable "max_size" {
  type        = number
  description = "Max node size"
  default     = 4
}
