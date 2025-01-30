################################################################################
# Common
################################################################################

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# EC2
################################################################################

variable "instance_type" {
  description = "EC2 instance type 'm6in.2xlarge' recommended for bandwidth intensive deployments"
  type        = string
  default     = "t2.medium" 
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "SSH keypair name"
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks for ingress access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks for egress access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "hostname" {
  description = "Server hostname, required for public derps"
  type        = string
  default     = "" 
}

variable "public_derp" {
  description = "Associates EIP with server instance"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "existing_eip_id" {
  description = "Existing Elastic IP allocation ID to use (optional)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Existing subnet ID to deploy EC2 in"
  type        = string
}

variable "security_group_id" {
  description = "Existing security group ID to use (optional)"
  type        = string
  default     = ""
}

variable "security_group_prefix" {
  description = "Security group prefix"
  type        = string
  default     = "devzero"
} 
