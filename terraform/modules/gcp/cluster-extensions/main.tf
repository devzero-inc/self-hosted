data "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region
}

################################################################################
# GKE Workload Identity (Equivalent to AWS IRSA) - Fixed
################################################################################
module "gke_workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "26.0.0"

  project_id          = var.project_id
  cluster_name        = data.google_container_cluster.this.name
  name                = "ebs-csi-controller-sa"
  namespace           = "kube-system"
  use_existing_gcp_sa = true
}

################################################################################
# GKE Network Policy Add-on (Replacing Deprecated Add-ons Module)
################################################################################
resource "google_container_cluster" "network_policy" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  network_policy {
    enabled  = true
    provider = "CALICO"
  }
}

################################################################################
# Persistent Disk (Equivalent to AWS EBS)
################################################################################
resource "kubernetes_storage_class" "pd_standard" {
  metadata {
    name = "pd-standard"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "pd.csi.storage.gke.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type      = "pd-standard"
  }
}

################################################################################
# Filestore (Equivalent to AWS EFS) - Fixed Implementation
################################################################################
resource "google_filestore_instance" "filestore" {
  count = var.enable_filestore ? 1 : 0

  name     = "${var.cluster_name}-filestore"
  project  = var.project_id
  location = var.region
  tier     = "STANDARD"

  file_shares {
    name        = "default"
    capacity_gb = 1024
  }

  networks {
    network            = "default"
    reserved_ip_range  = "10.0.0.0/29"
    modes              = ["MODE_IPV4"]
  }
}
