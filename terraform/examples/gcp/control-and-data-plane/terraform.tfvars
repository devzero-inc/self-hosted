# GCP Project
region     = "us-west2"
zone       = "us-west2-a"

# VPC
subnets = [
  {
    name          = "private-subnet-a"
    ip_cidr_range = "10.0.0.0/16"
    region        = "us-west2"
    secondary_ip_range = [
      {
        range_name    = "pods-ip-range"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "services-ip-range"
        ip_cidr_range = "10.2.0.0/16"
      }
    ]
  },
  {
    name               = "private-subnet-b"
    ip_cidr_range      = "10.3.0.0/16"
    region             = "us-west2"
    secondary_ip_range = []
  }
]

# GKE Cluster

# Cluster Name should not include (-, special char, and numbers)
cluster_name = "gke-test"
# Define IP Range Pods and Services based on what name you are giving in your VPC module
ip_range_pods              = "pods-ip-range"
ip_range_services          = "services-ip-range"
http_load_balancing        = true
horizontal_pod_autoscaling = true
gcp_filestore_csi_driver   = true
network_policy             = false
enable_private_endpoint    = false
enable_private_nodes       = true
# Master IPV4 CIDR Must be /28 subnet and should not overlap with any subnet or secondary range.
master_ipv4_cidr_block      = "10.190.0.0/28"
cluster_deletion_protection = false
cluster_auto_upgrade        = false

node_pools = [
  {
    name                   = "default-node-pool"
    machine_type           = "n1-standard-2"
    min_count              = 1
    max_count              = 3
    disk_size_gb           = 30
    disk_type              = "pd-standard"
    image_type             = "ubuntu_containerd"
    auto_repair            = true
    auto_upgrade           = true
    create_service_account = true
    preemptible            = false
    initial_node_count     = 2
  },
]

node_pools_oauth_scopes = {
  all = []

  default-node-pool = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}

node_pools_labels = {
  all = {}

  default-node-pool = {
    default-node-pool = true
  }
}

node_pools_tags = {
  all = []

  default-node-pool = [
    "default-node-pool",
  ]
}

# Filestore
instance_name   = "gke-filestore"
tier            = "STANDARD"
description     = "Used by GKE Cluster"
# file share name should not include - and special characters
file_share_name = "share1_devzero"
# Capacity must be atleast 1024 GiB
capacity_gb     = "1024"
filestore_labels = {
  "managed-by" = "terraform"
  "used-by"    = "gke"
}