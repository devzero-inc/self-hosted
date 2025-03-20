variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "gke_subnet_cidr" {
  description = "CIDR block for the GKE subnet"
  type        = string
}

variable "mtu" {
  description = "MTU for the network"
  type        = number
  default     = 1460
}

variable "create_vpc" {
  description = "Whether to create a VPC"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes in GKE"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint in GKE"
  type        = bool
  default     = false
}

variable "gke_cluster_ipv4_cidr" {
  description = "IPv4 range for pods"
  type        = string
}

variable "gke_services_ipv4_cidr" {
  description = "IPv4 range for services"
  type        = string
}

variable "gke_master_version" {
  description = "Kubernetes master version"
  type        = string
}

variable "gke_node_pool_name" {
  description = "Name of the node pool"
  type        = string
}

variable "gke_node_count" {
  description = "Number of nodes in node pool"
  type        = number
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}

variable "gke_threads_per_core" {
  description = "Threads per core for GKE nodes"
  type        = number
}

variable "gke_enable_nested_virtualization" {
  description = "Enable nested virtualization"
  type        = bool
}

variable "gke_cluster_location" {
  description = "The primary zone where the GKE cluster will be created (single-zone setup)."
  type        = string
}

variable "gke_zones" {
  description = "List of zones for the GKE cluster (for a single-zone cluster, provide one zone)."
  type        = list(string)
}

variable "gke_node_pools" {
  description = "List of node pools to be created"
  type        = list(object({
    name               = string
    machine_type       = string
    min_count          = number
    max_count          = number
    local_ssd_count    = number
    disk_size_gb       = number
    disk_type          = string
    image_type         = string
    enable_gcfs        = bool
    enable_gvnic       = bool
    logging_variant    = string
    auto_repair        = bool
    auto_upgrade       = bool
    preemptible        = bool
    initial_node_count = number
  }))
}
