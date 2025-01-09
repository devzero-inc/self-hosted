resource "google_container_cluster" "gke_cluster" {
  project  = var.project_id
  name     = var.cluster_name
  
  location = var.region
  network            = var.network
  subnetwork         = var.subnetwork
  deletion_protection = var.cluster_deletion_protection
  
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks_config
    content {
      dynamic "cidr_blocks" {
        for_each = master_authorized_networks_config.value.cidr_blocks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  addons_config {
    http_load_balancing {
      disabled = ! var.http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = ! var.horizontal_pod_autoscaling
    }

    gcp_filestore_csi_driver_config {
      enabled = var.gcp_filestore_csi_driver
    }

    network_policy_config {
      disabled = ! var.network_policy
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  lifecycle {
    ignore_changes = [node_pool, initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  node_pool {
    name               = "default-pool"
    initial_node_count = var.initial_node_count

    node_config {
      service_account = lookup(var.node_pools[0], "service_account", local.service_account)
    }
  }

  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  remove_default_node_pool = true

}

resource "google_container_node_pool" "pools" {
  count    = length(var.node_pools)
  name     = var.node_pools[count.index]["name"]
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.gke_cluster.name
  
  initial_node_count = lookup(
    var.node_pools[count.index],
    "initial_node_count",
    lookup(var.node_pools[count.index], "min_count", 1),
  )

  node_count = lookup(var.node_pools[count.index], "autoscaling", true) ? null : lookup(var.node_pools[count.index], "min_count", 1)

  dynamic "autoscaling" {
    for_each = lookup(var.node_pools[count.index], "autoscaling", true) ? [var.node_pools[count.index]] : []
    content {
      min_node_count = lookup(autoscaling.value, "min_count", 1)
      max_node_count = lookup(autoscaling.value, "max_count", 100)
    }
  }

  management {
    auto_repair  = lookup(var.node_pools[count.index], "auto_repair", true)
    auto_upgrade = lookup(var.node_pools[count.index], "auto_upgrade", var.cluster_auto_upgrade)
  }

  node_config {
    image_type   = lookup(var.node_pools[count.index], "image_type", "COS")
    machine_type = lookup(var.node_pools[count.index], "machine_type", "n1-standard-2")
    labels = merge(
      {
        "cluster_name" = var.cluster_name
      },
      {
        "node_pool" = var.node_pools[count.index]["name"]
      },
      var.node_pools_labels["all"],
      var.node_pools_labels[var.node_pools[count.index]["name"]],
    )

    tags = concat(
      ["gke-${var.cluster_name}"],
      ["gke-${var.cluster_name}-${var.node_pools[count.index]["name"]}"],
      var.node_pools_tags["all"],
      var.node_pools_tags[var.node_pools[count.index]["name"]],
    )

    disk_size_gb = lookup(var.node_pools[count.index], "disk_size_gb", 30)
    disk_type    = lookup(var.node_pools[count.index], "disk_type", "pd-standard")
    
    service_account = lookup(
      var.node_pools[count.index],
      "service_account",
      var.service_account,
    )
    preemptible = lookup(var.node_pools[count.index], "preemptible", false)

    oauth_scopes = concat(
      var.node_pools_oauth_scopes["all"],
      var.node_pools_oauth_scopes[var.node_pools[count.index]["name"]],
    )
  }
  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}