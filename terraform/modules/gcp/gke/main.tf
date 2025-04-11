resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.gke_cluster_location

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  deletion_protection     = false
  initial_node_count      = 1
  remove_default_node_pool = true
  datapath_provider       = "ADVANCED_DATAPATH"

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  network    = var.network
  subnetwork = var.subnetwork

  min_master_version = var.min_master_version
}

resource "google_container_node_pool" "default_pool" {
  cluster   = google_container_cluster.gke_cluster.name
  location  = google_container_cluster.gke_cluster.location
  name      = var.node_pool_name

  node_count = var.node_count

  dynamic "autoscaling" {
    for_each = var.enable_cluster_autoscaler ? [1] : []
    content {
      min_node_count = var.min_node_count
      max_node_count = var.max_node_count
    }
  }

  node_config {
    machine_type = var.machine_type
    image_type   = var.image_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    advanced_machine_features {
      threads_per_core           = 1
      enable_nested_virtualization = true
    }
  }
}
