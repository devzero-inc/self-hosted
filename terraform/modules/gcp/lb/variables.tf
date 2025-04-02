variable "name" {
  type        = string
  description = "Name prefix for resources"
  default     = "devzero"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "zone" {
  type        = string
  description = "GCP zone for the instance group"
  default     = "us-central1-a"
}

variable "ssl_certificate_id" {
  type        = string
  description = "Self-link to the SSL certificate for HTTPS"
}

variable "health_check" {
  type = object({
    path                = string
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
  })
  default = {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to associate with the Load Balancer"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for firewall rules"
}

variable "record" {
  type        = string
  description = "DNS record to be added for the Load Balancer"
}

variable "zone_id" {
  type        = string
  description = "Cloud DNS zone ID"
}
