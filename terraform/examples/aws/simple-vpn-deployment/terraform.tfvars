region = "us-west-1"
name   = "devzero"

# EKS
worker_instance_type = "m5.4xlarge"
desired_node_size    = 4
max_node_size        = 4

cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

create_separate_data_plane_cluster = false

# VPC
create_vpc               = true
create_vpn               = true
cidr                     = "10.0.0.0/16"
availability_zones_count = 3

# Existing VPC
# create_vpc = false
# vpc_id = "MY_VPC_ID"
# public_subnet_ids = ["MY_SUBNET_ID_1", "MY_SUBNET_ID_2"]
# private_subnet_ids = ["MY_SUBNET_ID_3", "MY_SUBNET_ID_3"]
# security_group_ids = ["MY_SECURITY_GROUP_ID"]

# Cluster
enable_cluster_autoscaler = false
