# GCP Project
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

# VPC
variable "subnets" {
  description = "Subnets configuration"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_range = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
}

# GKE Cluster

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "master_authorized_networks_config" {
  type        = list(object({ cidr_blocks = list(object({ cidr_block = string, display_name = string })) }))
  description = "The desired configuration options for master authorized networks. The object format is {cidr_blocks = list(object({cidr_block = string, display_name = string}))}. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "horizontal_pod_autoscaling" {
  type        = bool
  description = "Enable horizontal pod autoscaling addon"
  default     = true
}

variable "http_load_balancing" {
  type        = bool
  description = "Enable httpload balancer addon"
  default     = true
}

variable "kubernetes_dashboard" {
  type        = bool
  description = "Enable kubernetes dashboard addon"
  default     = false
}

variable "network_policy" {
  type        = bool
  description = "Enable network policy addon"
  default     = false
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

  default = [
    {
      name = "default-node-pool"
    },
  ]
}

variable "cluster_auto_upgrade" {
  type        = bool
  description = "Enable Auto Upgrade"
  default     = false
}

variable "node_pools_labels" {
  type        = map(map(string))
  description = "Map of maps containing node labels by node-pool name"

  default = {
    all               = {}
    default-node-pool = {}
  }
}

variable "node_pools_tags" {
  type        = map(list(string))
  description = "Map of lists containing node network tags by node-pool name"

  default = {
    all               = []
    default-node-pool = []
  }
}

variable "node_pools_oauth_scopes" {
  type        = map(list(string))
  description = "Map of lists containing node oauth scopes by node-pool name"

  default = {
    all               = ["https://www.googleapis.com/auth/cloud-platform"]
    default-node-pool = []
  }
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

variable "cluster_ipv4_cidr" {
  default     = ""
  description = "The IP address range of the kubernetes pods in this cluster. Default is an automatically assigned CIDR."
}

variable "enable_private_endpoint" {
  type        = bool
  description = "(Beta) Whether the master's internal IP address is used as the cluster endpoint"
  default     = false
}

variable "enable_private_nodes" {
  type        = bool
  description = "(Beta) Whether nodes have internal IP addresses only"
  default     = false
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "(Beta) The IP range in CIDR notation to use for the hosted master network"
  default     = "10.0.0.0/28"
}

variable "gcp_filestore_csi_driver" {
  type        = bool
  description = "Enable GCP Filestore CSI Driver addon"
  default     = true
}

variable "cluster_deletion_protection" {
  type        = bool
  description = "Cluster Deletion Protection for Terraform. Default is true. If it is true then you will not be able to delete it via terraform. You have to manually edit the terraform state file."
  default     = false
}


#Filestore

variable "instance_name" {
  description = "The name of the Filestore instance"
  type        = string
}

variable "tier" {
  description = "The tier of the Filestore instance (STANDARD or PREMIUM)"
  type        = string
  default     = "STANDARD"
}

variable "description" {
  description = "A description for the Filestore instance"
  type        = string
  default     = ""
}

variable "file_share_name" {
  description = "The name of the file share"
  type        = string
}

variable "capacity_gb" {
  description = "The capacity in GB for the file share"
  type        = number
}

variable "filestore_labels" {
  description = "A map of labels to assign to the Filestore instance"
  type        = map(string)
  default     = {}
}


#Vault
variable "vault_admin_user" {
  description = "Email of the Vault Admin User"
  type        = string
}
