provider "google" {
  project = "devzero-kubernetes-sandbox"
  region  = "us-central1"
}

resource "google_compute_subnetwork" "default_subnet" {
  name          = "gke-subnet"
  region        = "us-central1"
  network       = "default"  # Using the default VPC
  ip_cidr_range = "10.1.0.0/20"  # IPv4 range for the subnet
  stack_type    = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

resource "google_container_cluster" "gke_cluster" {
  name     = "garvit-kata"
  location = "us-central1"

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.8.0.0/16"  # IPv4 range for the pods
    services_ipv4_cidr_block = "10.4.0.0/20"  # IPv4 range for the services
    stack_type               = "IPV4_IPV6"   # Enable IPv6 support for the cluster
  }

  deletion_protection = false

  initial_node_count = 1
  remove_default_node_pool = true

  datapath_provider = "ADVANCED_DATAPATH"

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  network    = "default"  # Use the default network
  subnetwork = google_compute_subnetwork.default_subnet.name  # Reference the subnet
}

resource "google_container_node_pool" "default_pool" {
  cluster   = google_container_cluster.gke_cluster.name
  location  = google_container_cluster.gke_cluster.location
  name      = "kata-node-pool"

  node_config {
    machine_type = "n2-standard-4"
    advanced_machine_features {
      threads_per_core = 1
      enable_nested_virtualization = true
    }
  }

  initial_node_count = 1
}
