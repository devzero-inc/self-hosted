resource "google_filestore_instance" "filestore" {
  name        = var.instance_name
  tier        = var.tier
  description = var.description
  location    = var.zone
  project     = var.project_id
  networks {
    network = var.vpc_name
    modes   = ["MODE_IPV4"]
  }
  file_shares {
    name       = var.file_share_name
    capacity_gb = var.capacity_gb
  }

  labels = var.labels
}