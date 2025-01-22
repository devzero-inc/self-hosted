region = "us-west-1"
cluster_name   = "roblox-env"
domain = "devzero.internal"

# EKS
worker_instance_type = "m5.4xlarge"
desired_node_size    = 4
max_node_size        = 4

cluster_endpoint_public_access       = false
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# VPC
create_vpc               = true
create_vpn               = true
cidr                     = "10.8.0.0/16"
availability_zones_count = 3
create_igw               = true
one_nat_gateway_per_az   = true
single_nat_gateway       = false
enable_nat_gateway       = true
client_vpn_cidr_block    = "10.9.0.0/22"

vpn_client_list = [ "root", "mauro", "zvonimir", "everton" ]

# Existing VPC
# create_vpc = false
# vpc_id = "MY_VPC_ID"
# public_subnet_ids = ["MY_SUBNET_ID_1", "MY_SUBNET_ID_2"]
# private_subnet_ids = ["MY_SUBNET_ID_3", "MY_SUBNET_ID_3"]
# security_group_ids = ["MY_SECURITY_GROUP_ID"]

# Cluster
enable_cluster_autoscaler = false
