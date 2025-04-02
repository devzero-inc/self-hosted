output "subnet_secondary_ranges" {
  value = google_compute_subnetwork.gke_subnet.secondary_ip_range
}

output "gke_cluster_name" {
  value = resource.google_container_cluster.gke_cluster.name
}

output "vpc_id" {
  value = resource.google_compute_network.vpc_network.name
}

output "derp_ip" {
  value = length(module.derp) > 0 ? module.derp[0].derp_ip : null
}

output "derp_ssh_private_key" {
  value = length(module.derp) > 0 ? module.derp[0].private_key_pem : null
  description = "Private key to SSH into the DERP server"
  sensitive   = true
}
