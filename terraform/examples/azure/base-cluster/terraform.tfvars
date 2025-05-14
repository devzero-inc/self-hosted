resource_group_name = "dev-test"
location            = "eastus"
cluster_name        = "devzero"
cluster_version     = "1.30"
cidr                = "10.240.0.0/16"

cluster_endpoint_public_access = true
enable_private_cluster = false
enable_rbac = false
admin_group_object_ids = [
  "00000000-0000-0000-0000-000000000000"
]

instance_type = "Standard_D8s_v3"
enable_cluster_autoscaler = false
node_count   = 2
min_size       = 1
max_size       = 3

enable_nat_gateway   = true
single_nat_gateway   = true

# Optional tagging

tags = {
  environment = "dev"
  owner       = "devzero"
  createdBy   = "terraform"
}

create_derp = false
public_derp = false

create_vault_auto_unseal_key = false

create_vpn = true