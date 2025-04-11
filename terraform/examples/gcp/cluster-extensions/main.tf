################################################################################
# Providers
################################################################################

provider "google" {
  project = var.project_id
  region  = var.location
}

data "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.location
  project  = var.project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

################################################################################
# Cluster Extensions Module
################################################################################

module "cluster_extensions" {
  source = "../../../modules/gcp/cluster_extensions"

  project_id                             = var.project_id
  location                               = var.location
  cluster_name                           = var.cluster_name
  vpc_name                               = "${var.cluster_name}-vpc"
  tags                                   = var.tags

  enable_pd_csi_driver                   = var.enable_pd_csi_driver
  enable_cluster_autoscaler              = var.enable_cluster_autoscaler
  cluster_autoscaler_chart_version       = var.cluster_autoscaler_chart_version

  disable_existing_default_storage_class = var.disable_existing_default_storage_class
  previous_default_storage_class_name    = var.previous_default_storage_class_name

  enable_filestore                       = var.enable_filestore
  efs_capacity_gb                        = var.efs_capacity_gb
  filestore_reserved_ip_range            = var.filestore_reserved_ip_range
}
