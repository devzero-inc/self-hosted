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

variable "ami_id" {
  type        = string
  description = "ID of the AMI used to deploy node group, default AMI is in us-west-2 for EKS 1.30"
  default     = "ami-01e03fd5293f4b786"
}

variable "nodes_key_name" {
  description = "Nodes Kay Pair name"
  default     = ""
}

variable "node_group_suffix" {
  description = "Suffix to use on the node group name"
  default     = "-kata-nodes"
}

variable "node_role_suffix" {
  description = "Suffix to use on the node group IAM role"
  default     = "-nodes-eks-kata-"
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

variable "subnet_ids" {
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME`"
  type        = list(string)
  default     = null
}
