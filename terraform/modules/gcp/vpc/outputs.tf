output "vpc_network_id" {
  value       = google_compute_network.vpc_network.id
  description = "VPC network ID"
}

output "vpc_network_name" {
  value       = google_compute_network.vpc_network.name
  description = "VPC network name"
}

output "gke_subnet_id" {
  value       = google_compute_subnetwork.gke_subnet.id
  description = "GKE Subnet ID"
}

output "gke_subnet_name" {
  value       = google_compute_subnetwork.gke_subnet.name
  description = "GKE Subnet name"
}
