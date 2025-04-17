# General
prefix = "devzero"
project_id = "devzero-self-hosted"
region = "us-central1"

domain       = "devzero.internal"

# VPC
gke_subnet_cidr = "10.1.0.0/20"
mtu = 1460
create_vpc = true
pods_secondary_range_cidr = "10.12.0.0/16"
services_secondary_range_cidr = "10.14.0.0/20"

# NAT Gateway (Enable only if using private nodes)
enable_private_nodes = false
enable_private_endpoint = false

# GKE Cluster (Single-Zone)
gke_cluster_location = "us-central1-a"  
gke_zones = ["us-central1-a"]
gke_master_version = "1.31.6-gke.1020000"
node_count = 3
machine_type = "n2-highcpu-32"
devzero_service_account = "devzero-self-hosted@devzero-self-hosted.iam.gserviceaccount.com"

# Vault
create_vault_crypto_key = false
vault_key_ring_name = "devzero-key-ring"
vault_key_ring_location = "global"

enable_cluster_autoscaler = false

create_derp = false

create_vpn = false
vpn_client_list = ["root"]