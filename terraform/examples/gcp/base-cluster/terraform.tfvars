# General
prefix = "garvit"
project_id = "devzero-kubernetes-sandbox"
region = "us-central1"

# VPC
gke_subnet_cidr = "10.1.0.0/20"
mtu = 1460
create_vpc = false

# NAT Gateway (Enable only if using private nodes)
enable_private_nodes = false
enable_private_endpoint = false

# GKE Cluster (Single-Zone)
gke_cluster_location = "us-central1-a"  
gke_zones = ["us-central1-a"]  # ✅ Single-zone explicitly set
gke_cluster_ipv4_cidr = "10.8.0.0/16"
gke_services_ipv4_cidr = "10.4.0.0/20"
gke_master_version = "1.31.6-gke.1020000"

gke_enable_nested_virtualization = true
gke_machine_type = "n2-highcpu-32"
gke_node_count = 1
gke_node_pool_name = "default-pool"
gke_threads_per_core = 1

# GKE Node Pool (Single Node)
gke_node_pools = [
  {
    name               = "default-node-pool"
    machine_type       = "n2-highcpu-32"
    min_count          = 1
    max_count          = 1
    local_ssd_count    = 0
    disk_size_gb       = 100
    disk_type          = "pd-standard"
    image_type         = "UBUNTU_CONTAINERD"
    enable_gcfs        = false
    enable_gvnic       = false
    logging_variant    = "DEFAULT"
    auto_repair        = true
    auto_upgrade       = true
    preemptible        = false
    initial_node_count = 1
  }
]
