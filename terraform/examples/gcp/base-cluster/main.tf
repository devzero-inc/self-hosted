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

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

################################################################################
# VPC - DIRECT RESOURCES INSTEAD OF MODULE
################################################################################
resource "google_compute_network" "vpc_network" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  mtu                     = var.mtu
  project                 = var.project_id
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = local.subnet_name
  ip_cidr_range = var.gke_subnet_cidr  # "10.1.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.project_id

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = "10.12.0.0/16"  # Changed from 10.8.0.0/16
  }

  secondary_ip_range {
    range_name    = local.services_range_name
    ip_cidr_range = "10.14.0.0/20"  # Changed from 10.4.0.0/20
  }
}

resource "google_compute_route" "default_route" {
  name             = "${local.prefix}-default-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  project          = var.project_id
}

################################################################################
# OPTIONAL: NAT Router & NAT Gateway (Only if using private nodes)
################################################################################
resource "google_compute_router" "nat_router" {
  count   = var.enable_private_nodes ? 1 : 0
  name    = "${local.prefix}-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  count   = var.enable_private_nodes ? 1 : 0
  name    = "${local.prefix}-nat"
  router  = google_compute_router.nat_router[0].name
  region  = var.region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

################################################################################
# GKE CLUSTER MODULE
################################################################################
resource "google_container_cluster" "gke_cluster" {
  name     = "${local.prefix}"
  location = var.gke_cluster_location

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
    # Or specify the CIDR blocks directly:
    # cluster_ipv4_cidr_block  = "10.12.0.0/16"
    # services_ipv4_cidr_block = "10.14.0.0/20"
  }

  deletion_protection = false

  initial_node_count = 1
  remove_default_node_pool = true

  datapath_provider = "ADVANCED_DATAPATH"

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    # master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  min_master_version = "1.31.6-gke.1020000" 
}

resource "google_container_node_pool" "default_pool" {
  cluster   = google_container_cluster.gke_cluster.name
  location  = google_container_cluster.gke_cluster.location
  name      = "kata-node-pool"

  node_count = 1

  node_config {
    machine_type = "n2-highcpu-32"
    image_type   = "UBUNTU_CONTAINERD"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    advanced_machine_features {
      threads_per_core = 1
      enable_nested_virtualization = true
    }
  }
}

################################################################################
# Vault Auto-Unseal Key
################################################################################
data "google_kms_key_ring" "vault" {
  name     = var.vault_key_ring_name
  location = var.vault_key_ring_location
  project  = var.project_id
}

resource "google_kms_crypto_key" "vault" {
  count    = var.create_vault_crypto_key ? 1 : 0
  name     = "${local.prefix}-crypto-key"
  key_ring = "projects/${var.project_id}/locations/${var.vault_key_ring_location}/keyRings/${var.vault_key_ring_name}"
  purpose  = "ENCRYPT_DECRYPT"
  destroy_scheduled_duration = "86400s" # 24h

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_iam_member" "vault" {
  count         = var.create_vault_crypto_key ? 1 : 0
  crypto_key_id = google_kms_crypto_key.vault[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.vault_unseal_service_account}"
}

resource "google_service_account_iam_binding" "vault_wi_binding" {
  count              = var.create_vault_crypto_key ? 1 : 0
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.vault_unseal_service_account}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[devzero/vault]"
  ]
}