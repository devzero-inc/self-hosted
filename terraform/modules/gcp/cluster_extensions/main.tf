#########################################
# Filestore
#########################################

resource "google_filestore_instance" "primary" {
  count     = var.enable_filestore ? 1 : 0
  name      = "${var.cluster_name}-filestore"
  location  = var.location
  tier      = "STANDARD"
  project   = var.project_id

  file_shares {
    name        = "vol1"
    capacity_gb = var.efs_capacity_gb
  }

  networks {
    network            = var.vpc_name
    modes              = ["MODE_IPV4"]
    reserved_ip_range  = var.filestore_reserved_ip_range
  }

  labels = var.tags
}

resource "kubernetes_storage_class" "filestore" {
  count = var.enable_filestore ? 1 : 0

  metadata {
    name = "efs-etcd"
  }

  storage_provisioner = "filestore.csi.storage.gke.io"
  reclaim_policy = "Delete"

  parameters = {
    volume = "vol1"
    instance = "${var.cluster_name}-filestore"
    # Add network parameter
    network = var.vpc_name
  }

  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}
