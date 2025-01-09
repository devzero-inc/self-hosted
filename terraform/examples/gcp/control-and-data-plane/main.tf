################################################################################
# Providers
################################################################################

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

################################################################################
# Enable required APIs
################################################################################

resource "google_project_service" "cloud_kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_api" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "filestore_api" {
  project = var.project_id
  service = "file.googleapis.com"
  disable_on_destroy = false
}


################################################################################
# Common resources
################################################################################

resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source = "../../../modules/gcp/vpc"

  project_id = var.project_id
  region     = var.region
  vpc_name   = "${terraform.workspace}-${random_string.this.result}-vpc"
  prefix     = random_string.this.result
  subnets    = var.subnets
}

################################################################################
# GKE
################################################################################

module "gke" {
  source = "../../../modules/gcp/gke"

  project_id = var.project_id
  # Cluster Name should not include (-, special char, and numbers)
  cluster_name = "gke${random_string.this.result}"
  region       = var.region
  network      = module.vpc.vpc_name
  subnetwork   = module.vpc.vpc_subnets[0]
  # Define IP Range Pods and Services based on what name you are giving in your VPC module
  ip_range_pods              = "pods-ip-range"
  ip_range_services          = "services-ip-range"
  http_load_balancing        = var.http_load_balancing
  horizontal_pod_autoscaling = var.horizontal_pod_autoscaling
  cluster_auto_upgrade       = var.cluster_auto_upgrade
  gcp_filestore_csi_driver   = var.gcp_filestore_csi_driver
  network_policy             = var.network_policy
  enable_private_endpoint    = var.enable_private_endpoint
  enable_private_nodes       = var.enable_private_nodes
  # Master IPV4 CIDR Must be /28 subnet and should not overlap with any subnet or secondary range.
  master_ipv4_cidr_block      = var.master_ipv4_cidr_block
  cluster_deletion_protection = var.cluster_deletion_protection
  node_pools                  = var.node_pools
  node_pools_oauth_scopes     = var.node_pools_oauth_scopes
  node_pools_labels           = var.node_pools_labels
  node_pools_tags             = var.node_pools_tags

  depends_on = [ module.filestore ]
}

################################################################################
# Filestore
################################################################################

module "filestore" {
  source = "../../../modules/gcp/filestore"

  zone            = var.zone
  project_id      = var.project_id
  vpc_name        = module.vpc.vpc_name
  instance_name   = var.instance_name
  tier            = var.tier
  description     = var.description
  file_share_name = var.file_share_name
  capacity_gb     = var.capacity_gb
  labels          = var.filestore_labels
}

################################################################################
# Vault
################################################################################

# Service Account for Vault
resource "google_service_account" "vault_service_account" {
  account_id   = "vault-service-account"
  display_name = "Vault Service Account"
}

# Grant 'roles/cloudkms.cryptoKeyEncrypterDecrypter' to the Vault Service Account
resource "google_project_iam_binding" "vault_kms_binding" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_service_account.vault_service_account.email}",
  ]
}

# Grant 'roles/cloudkms.admin' to the Vault Admin User
resource "google_project_iam_binding" "vault_admin_binding" {
  project = var.project_id
  role    = "roles/cloudkms.admin"

  members = [
    "user:${var.vault_admin_user}",
  ]
}

# Create a KeyRing for Vault
resource "google_kms_key_ring" "vault_key_ring" {
  name     = "vault-key-ring-2"
  location = "global"
}

# Create a CryptoKey for Vault Auto-Unseal
resource "google_kms_crypto_key" "vault_crypto_key" {
  name            = "vault-auto-unseal-2"
  key_ring        = google_kms_key_ring.vault_key_ring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2592000s" # 30 days
  depends_on = [google_project_service.cloud_kms_api]
}

# Bind the Vault Service Account to the CryptoKey with IAM Permissions
resource "google_kms_crypto_key_iam_binding" "vault_crypto_key_binding" {
  crypto_key_id = google_kms_crypto_key.vault_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  depends_on = [google_project_service.cloud_kms_api]
  members = [
    "serviceAccount:${google_service_account.vault_service_account.email}",
  ]
}

# Bind the Vault Admin User to the CryptoKey with Admin Permissions
resource "google_kms_crypto_key_iam_binding" "vault_crypto_key_admin_binding" {
  crypto_key_id = google_kms_crypto_key.vault_crypto_key.id
  role          = "roles/cloudkms.admin"

  members = [
    "user:${var.vault_admin_user}",
  ]
}
