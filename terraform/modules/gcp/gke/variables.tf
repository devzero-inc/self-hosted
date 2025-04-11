variable "cluster_name" {}
variable "gke_cluster_location" {}
variable "pods_range_name" {}
variable "services_range_name" {}
variable "project_id" {}
variable "network" {}
variable "subnetwork" {}
variable "min_master_version" { default = "1.31.6-gke.1020000" }

variable "node_pool_name" { default = "kata-node-pool" }
variable "node_count" { default = 3 }
variable "machine_type" { default = "n2-highcpu-32" }
variable "image_type" { default = "UBUNTU_CONTAINERD" }

variable "enable_cluster_autoscaler" { default = false }
variable "min_node_count" { default = 1 }
variable "max_node_count" { default = 5 }
