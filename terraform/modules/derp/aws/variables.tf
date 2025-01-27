variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = ""
}

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
  description = "ssh keypair name"
  type        = string
  default     = ""
}

variable "hostname" {
  description = "server host name, required for public derps"
  type        = string
  default     = "" 
}

variable "public_derp" {
  description = "associates EIP with server instance"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use (optional)"
  type        = string
  default     = ""
}

variable "existing_eip_id" {
  description = "Existing Elastic IP allocation ID to use (optional)"
  type        = string
  default     = ""
}

variable "existing_subnet_id" {
  description = "Existing subnet ID to use (optional)"
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "Existing security group ID to use (optional)"
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}