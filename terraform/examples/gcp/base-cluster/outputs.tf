output "subnet_secondary_ranges" {
  value = google_compute_subnetwork.gke_subnet.secondary_ip_range
}

output "gke_cluster_name" {
  value = resource.google_container_cluster.gke_cluster.name
}

# output "gke_cluster_endpoint" {
#   value = google_container_cluster.gke_cluster_endpoint
# }

# output "gke_cluster_kubernetes_version" {
#   value = google_container_cluster.gke_cluster.min_master_version
# }

# output "gke_node_pool_version" {
#   value = google_container_node_pool.default_pool.version
# }
