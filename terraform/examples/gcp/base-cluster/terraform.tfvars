# General
prefix = "devzero"
project_id = "devzero-kubernetes-sandbox"
region = "us-central1"

domain       = "devzero.internal"

# VPC
gke_subnet_cidr = "10.1.0.0/20"
mtu = 1460
create_vpc = true

# NAT Gateway (Enable only if using private nodes)
enable_private_nodes = false
enable_private_endpoint = false

# GKE Cluster (Single-Zone)
gke_cluster_location = "us-central1-a"  
gke_zones = ["us-central1-a"]
gke_master_version = "1.31.6-gke.1020000"

# Vault
create_vault_crypto_key = false
devzero_service_account = "dsh-testing-github-actions@devzero-kubernetes-sandbox.iam.gserviceaccount.com"
vault_key_ring_name = "devzero-key-ring"
vault_key_ring_location = "global"

enable_cluster_autoscaler = false

create_derp = false

create_vpn = false
vpn_client_list = ["root"]