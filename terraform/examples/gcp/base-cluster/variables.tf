################################################################################
# Common
################################################################################
variable "cluster_name" {
  type        = string
  description = "Name prefix for resources"
  default     = "devzero"
  validation {
    condition     = length(var.cluster_name) < 39
    error_message = "Cluster name must be less than 39 characters."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# GCP Project & Region
################################################################################
variable "project_id" {
  description = "GCP Project ID where the cluster will be deployed"
  type        = string
}

variable "region" {
  description = "GCP Region for resource deployment"
  type        = string
}

################################################################################
# VPC
################################################################################
variable "create_vpc" {
  description = "Create a new VPC if true, else use an existing one"
  type        = bool
}

variable "vpc_id" {
  description = "ID of an existing VPC (required if create_vpc is false)"
  type        = string
  default     = null
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = null
}

variable "subnet_mode" {
  description = "Mode for subnet creation (AUTO or CUSTOM)"
  type        = string
  default     = "CUSTOM"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (if using an existing VPC)"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (if using an existing VPC)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable a NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "subnetwork" {
  description = "Subnetwork to deploy GKE cluster"
  type        = string
}

variable "ip_range_pods" {
  description = "IP range for GKE pods"
  type        = string
}

variable "ip_range_services" {
  description = "IP range for GKE services"
  type        = string
}

################################################################################
# GKE Cluster
################################################################################
variable "cluster_version" {
  description = "GKE Cluster version"
  type        = string
  default     = "1.30"
}

variable "enable_private_endpoint" {
  description = "Enable private cluster endpoint"
  type        = bool
  default     = true
}

variable "enable_master_authorized_networks" {
  description = "Restrict cluster control plane access to specific CIDRs"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks allowed to access the control plane"
  type        = list(map(string))
  default     = []
}

variable "node_pools" {
  description = "Configuration for node pools"
  type = list(object({
    name         = string
    machine_type = string
    disk_size    = number
    min_count    = number
    max_count    = number
  }))
  default = [
    {
      name         = "default-pool"
      machine_type = "e2-standard-4"
      disk_size    = 100
      min_count    = 1
      max_count    = 4
    }
  ]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "client_vpn_cidr_block" {
  description = "CIDR block for VPN clients"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "create_alb" {
  description = "Whether to create an application load balancer"
  type        = bool
  default     = false
}

variable "create_vault_auto_unseal_key" {
  description = "Whether to create a KMS key for Vault auto unsealing"
  type        = bool
  default     = false
}

################################################################################
# VPN
################################################################################
variable "create_vpn" {
  description = "Enable VPN setup"
  type        = bool
  default     = false
}

variable "vpn_tunnel_cidr" {
  description = "CIDR range for VPN tunnel"
  type        = string
  default     = "10.9.0.0/22"
}

variable "vpn_peer_ip" {
  description = "Public IP of the VPN peer"
  type        = string
  default     = null
}

variable "vpn_shared_secret" {
  description = "Shared secret for VPN"
  type        = string
  default     = null
}

variable "pem_private_key" {
  description = "Path to the VPN private key"
  type        = string
  default     = null
}

variable "pem_certificate" {
  description = "Path to the VPN certificate"
  type        = string
  default     = null
}


################################################################################
# Cloud DNS
################################################################################
variable "domain" {
  description = "Domain name for private DNS"
  type        = string
}

variable "use_existing_dns_zone" {
  description = "Use an existing DNS zone if true"
  type        = bool
  default     = true
}

variable "existing_dns_zone_id" {
  description = "Existing DNS zone ID (if use_existing_dns_zone is true)"
  type        = string
  default     = null
}

variable "use_existing_cloud_dns_zone" {
  description = "If true, use an existing Cloud DNS zone"
  type        = bool
  default     = false
}


################################################################################
# Load Balancer
################################################################################
variable "create_lb" {
  description = "Create a Load Balancer"
  type        = bool
  default     = false
}

variable "lb_target_port" {
  description = "Port to forward traffic from the LB"
  type        = number
  default     = 80
}

################################################################################
# Firewall Rules
################################################################################
variable "enable_firewall" {
  description = "Enable firewall rules for cluster"
  type        = bool
  default     = true
}

variable "firewall_rules" {
  description = "Firewall rules for the cluster"
  type = list(object({
    name        = string
    description = string
    priority    = number
    direction   = string
    source_ips  = list(string)
    target_tags = list(string)
    allow = list(object({
      protocol = string
      ports    = list(number)
    }))
  }))
  default = [
    {
      name        = "allow-ssh"
      description = "Allow SSH access"
      priority    = 1000
      direction   = "INGRESS"
      source_ips  = ["0.0.0.0/0"]
      target_tags = ["ssh"]
      allow = [
        {
          protocol = "tcp"
          ports    = [22]
        }
      ]
    }
  ]
}

################################################################################
# Cloud KMS
################################################################################
variable "create_kms_key" {
  description = "Create a Cloud KMS key for Vault"
  type        = bool
  default     = false
}

variable "kms_key_purpose" {
  description = "Purpose of the KMS key"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

################################################################################
# DERP (Distributed Relay for Private Networks)
################################################################################
variable "create_derp" {
  description = "Enable a DERP server"
  type        = bool
  default     = false
}
