variable "region" {
  type        = string
  description = "The region to host the cluster in (required)"
}

variable "project_id" {
  type        = string
  description = "The project to create the resources in"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required)"
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in (required)"
}

variable "master_authorized_networks_config" {
  type        = list(object({ cidr_blocks = list(object({ cidr_block = string, display_name = string })) }))
  description = "The desired configuration options for master authorized networks. The object format is {cidr_blocks = list(object({cidr_block = string, display_name = string}))}. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "horizontal_pod_autoscaling" {
  type        = bool
  description = "Enable horizontal pod autoscaling addon"
}

variable "http_load_balancing" {
  type        = bool
  description = "Enable httpload balancer addon"
}

variable "gcp_filestore_csi_driver" {
  type        = bool
  description = "Enable GCP Filestore CSI Driver addon"
}

variable "network_policy" {
  type        = bool
  description = "Enable network policy addon"
}

variable "ip_range_pods" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
}

variable "ip_range_services" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services"
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
  default     = 0
}

variable "node_pools" {
  type        = list(map(string))
  description = "List of maps containing node pools"
}

variable "cluster_auto_upgrade" {
  type        = bool
  description = "Enable Auto Upgrade"
}

variable "node_pools_labels" {
  type        = map(map(string))
  description = "Map of maps containing node labels by node-pool name"
}

variable "node_pools_tags" {
  type        = map(list(string))
  description = "Map of lists containing node network tags by node-pool name"
}

variable "node_pools_oauth_scopes" {
  type        = map(list(string))
  description = "Map of lists containing node oauth scopes by node-pool name"
}

variable "create_service_account" {
  type        = bool
  description = "Defines if service account specified to run nodes should be created."
  default     = true
}

variable "grant_registry_access" {
  type        = bool
  description = "Grants created cluster-specific service account storage.objectViewer role."
  default     = false
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created."
  default     = ""
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether the master's internal IP address is used as the cluster endpoint"
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network. This range must not overlap with any other ranges in use within the cluster's network, and it must be a /28 subnet"
}

variable "cluster_deletion_protection" {
  type        = bool
  description = "Cluster Deletion Protection for Terraform. Default is true. If it is true then you will not be able to delete it via terraform. You have to manually edit the terraform state file."
}