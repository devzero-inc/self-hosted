locals {
  prefix = var.prefix
  subnet_name = "${local.prefix}-gke-subnet"
  pods_range_name = "pods-range"
  services_range_name = "services-range"
}

################################################################################
# PROVIDERS
################################################################################

provider "google" {
  project = var.project_id
  region  = var.region
}

################################################################################
# VPC
################################################################################
module "vpc" {
  source                        = "../../../modules/gcp/vpc"
  project_id                    = var.project_id
  region                        = var.region
  mtu                           = var.mtu
  gke_subnet_cidr               = var.gke_subnet_cidr
  prefix                        = local.prefix
  subnet_name                   = local.subnet_name
  pods_range_name               = local.pods_range_name
  services_range_name           = local.services_range_name
  pods_secondary_range_cidr     = var.pods_secondary_range_cidr
  services_secondary_range_cidr = var.services_secondary_range_cidr
}

################################################################################
# OPTIONAL: NAT Router & NAT Gateway (Only if using private nodes)
################################################################################
module "nat_gateway" {
  source = "../../../modules/gcp/nat"

  count      = var.enable_private_nodes ? 1 : 0
  prefix     = local.prefix
  region     = var.region
  network    = module.vpc.vpc_network_id
  project_id = var.project_id
}

################################################################################
# GKE CLUSTER
################################################################################
module "gke_cluster" {
  source = "../../../modules/gcp/gke"

  cluster_name              = local.prefix
  gke_cluster_location      = var.gke_cluster_location
  pods_range_name           = local.pods_range_name
  services_range_name       = local.services_range_name
  project_id                = var.project_id
  network                   = module.vpc.vpc_network_name
  subnetwork                = module.vpc.gke_subnet_name
  min_master_version        = "1.31.6-gke.1020000"

  node_pool_name            = "kata-node-pool"
  node_count                = var.node_count
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  min_node_count            = 1
  max_node_count            = 5
}

################################################################################
# VPN
################################################################################
module "vpn" {
  count = var.create_vpn ? 1 : 0

  source = "../../../modules/gcp/vpn"

  name               = local.prefix
  project_id         = var.project_id
  region             = var.region
  location           = var.gke_cluster_location
  network            = module.vpc.vpc_network_name
  subnet             = module.vpc.gke_subnet_name
  vpn_client_list    = var.vpn_client_list
  bucket_location    = var.region
  machine_type       = "e2-medium"
  devzero_service_account = var.devzero_service_account
  boot_image         = data.google_compute_image.ubuntu.self_link
  additional_server_dns_names = [
    "${var.domain}",
    "*.${var.domain}"
  ]
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}


################################################################################
# Example of using custom DERP server in GCP
################################################################################
module "derp" {
  source = "../../../modules/gcp/derp"

  count  = var.create_derp ? 1 : 0

  region    = var.region
  zone      = var.gke_cluster_location

  network     = module.vpc.vpc_network_id
  subnetwork  = module.vpc.gke_subnet_id

  instance_type = "e2-medium"
  volume_size   = 20

  public_derp   = true
  existing_ip   = ""

  name_prefix   = "devzero"
  hostname      = "derp.devzero.net"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  service_account_email = var.devzero_service_account

  tags = {
    environment = "production"
    team        = "devops"
    project     = "derp"
  }
}

################################################################################
# Vault Auto-Unseal Key
################################################################################
module "vault" {
  count                    = var.create_vault_crypto_key ? 1 : 0
  source                   = "../../../modules/gcp/vault"
  vault_key_ring_name      = var.vault_key_ring_name
  vault_key_ring_location  = var.vault_key_ring_location
  project_id               = var.project_id
  devzero_service_account  = var.devzero_service_account
  create_vault_crypto_key  = var.create_vault_crypto_key
}

