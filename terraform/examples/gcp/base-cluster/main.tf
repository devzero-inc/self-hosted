locals {
  prefix = var.prefix
  subnet_name = "${local.prefix}-gke-subnet"
  pods_range_name = "pods-range"
  services_range_name = "services-range"
  subnet_key          = "${var.region}/${local.subnet_name}"
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
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"

  project_id   = var.project_id
  network_name = "${local.prefix}-vpc"
  routing_mode = "GLOBAL"
  mtu          = var.mtu

  subnets = [
    {
      subnet_name           = local.subnet_name
      subnet_ip             = var.gke_subnet_cidr
      subnet_region         = var.region
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    "${local.subnet_name}" = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = var.pods_secondary_range_cidr
      },
      {
        range_name    = local.services_range_name
        ip_cidr_range = var.services_secondary_range_cidr
      }
    ]
  }

  routes = [
    {
      name              = "${local.prefix}-default-route"
      description       = "Default route to internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}

################################################################################
# OPTIONAL: NAT Router & NAT Gateway (Only if using private nodes)
################################################################################
module "nat_gateway" {
  source = "../../../modules/gcp/nat"

  count      = var.enable_private_nodes ? 1 : 0
  prefix     = local.prefix
  region     = var.region
  network    = module.vpc.network_id
  project_id = var.project_id
}

################################################################################
# GKE CLUSTER
################################################################################
module "gke_cluster" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = local.prefix
  region                     = var.region
  network                    = module.vpc.network_name
  subnetwork                 = module.vpc.subnets_names[0]
  ip_range_pods              = local.pods_range_name
  ip_range_services          = local.services_range_name

  datapath_provider          = "ADVANCED_DATAPATH"
  deletion_protection        = false
  remove_default_node_pool   = true
  identity_namespace         = "${var.project_id}.svc.id.goog"

  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = true
  kubernetes_version         = "1.31.6-gke.1064001"

  node_pools = [
    {
      name             = "kata-node-pool"
      machine_type     = var.machine_type
      node_count       = var.node_count
      min_count        = 1
      max_count        = 5
      image_type       = "UBUNTU_CONTAINERD"
      auto_repair      = true
      service_account  = var.devzero_service_account
      enable_nested_virtualization = true
    }
  ]

  node_pools_tags = {
    kata-node-pool = ["kata-node-pool"]
  }

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
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
  network            = module.vpc.network_name
  subnet             = module.vpc.subnets_ids[local.subnet_key]
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

  network     = module.vpc.network_id
  subnetwork  = module.vpc.subnets_ids[local.subnet_key]

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

