output "node_pool_name" {
  description = "The name of the created node pool"
  value       = google_container_node_pool.kata_node_pool.name
}
