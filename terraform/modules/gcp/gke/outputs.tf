output "gke_cluster_name" {
  value = resource.google_container_cluster.gke_cluster.name
}