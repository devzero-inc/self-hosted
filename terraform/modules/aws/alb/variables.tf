variable "name" {
  type        = string
  description = "Name prefix to be used by resources"
  default     = "devzero"
}

variable "record" {
  type        = string
  description = "Record to be added for the ALB"
}

variable "zone_id" {
  type        = string
  description = "Zone id to attach domain to"
}

variable "additional_security_group_ids" {
  description = "VPC security groups to allow connection from/to vpn"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  type    = string
  description = "VPC ID to associate with the Client VPN endpoint"
}

variable "target_port" {
  type    = number 
  description = "Target port for the service"
}

variable "subnet_ids" {
  description = "Subnet IDs to associate with the Client VPN endpoint"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  type    = string
  description = "VPC CIDR block"
}

variable "type" {
  type        = string
  description = "Type of the load balancer"
  default     = "application"
}

variable "certificate_arn" {
  description = "Certificate ARN to be used with load balancer"
  type        = string
}

variable "health_check" {
  description = "Configuration for the health check"
  type = object({
    enabled             = bool
    path                = string
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
    matcher             = string
  })
  default = {
    enabled             = true
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

variable "node_group_asg_names" {
  description = "Map of Auto Scaling Group names for the ALB"
  type        = map(string)
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
