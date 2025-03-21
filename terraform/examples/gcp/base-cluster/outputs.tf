output "subnet_secondary_ranges" {
  value = google_compute_subnetwork.gke_subnet.secondary_ip_range
}

output "gke_cluster_name" {
  value = resource.google_container_cluster.gke_cluster.name
}