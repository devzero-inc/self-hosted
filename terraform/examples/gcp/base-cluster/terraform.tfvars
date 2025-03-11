# General Settings
region       = "us-west1"
project_id   = "my-gcp-project"
cluster_name = "devzero-dsh"
domain       = "devzero.internal"

# GKE
machine_type  = "e2-standard-4"
max_size      = 4
min_size      = 1
desired_size  = 1

cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# VPN
create_vpn            = false
client_vpn_cidr_block = "10.9.0.0/22"
vpn_client_list       = ["root"]

# VPC
create_vpc          = true
network_name        = "devzero-vpc"
cidr               = "10.8.0.0/16"
subnet_cidr_blocks = ["10.8.1.0/24", "10.8.2.0/24", "10.8.3.0/24"]

# NAT & Internet Access
create_nat_gateway      = true
single_nat_gateway      = true
one_nat_gateway_per_subnet = false
create_cloud_router     = true

# Existing VPC (if not creating a new one)
# create_vpc = false
# vpc_id = "MY_VPC_ID"
# public_subnet_ids = ["MY_SUBNET_ID_1", "MY_SUBNET_ID_2"]
# private_subnet_ids = ["MY_SUBNET_ID_3", "MY_SUBNET_ID_4"]

# Optional Services
create_derp = false
