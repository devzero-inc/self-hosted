region       = "us-west-1"
cluster_name = "devzero-dsh"
domain       = "devzero.internal"

# EKS
instance_type = "m5.4xlarge"
max_size      = 4
min_size      = 1
desired_size  = 1

cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]


# VPN
create_vpn            = false
client_vpn_cidr_block = "10.9.0.0/22"
vpn_client_list = ["root"]

# VPC
create_vpc               = true
cidr                     = "10.8.0.0/16"
availability_zones_count = 3

create_igw             = true
enable_nat_gateway     = true
one_nat_gateway_per_az = false
single_nat_gateway     = true

# Existing VPC
# create_vpc = false
# vpc_id = "MY_VPC_ID"
# public_subnet_ids = ["MY_SUBNET_ID_1", "MY_SUBNET_ID_2"]
# private_subnet_ids = ["MY_SUBNET_ID_3", "MY_SUBNET_ID_3"]
# security_group_ids = ["MY_SECURITY_GROUP_ID"]
