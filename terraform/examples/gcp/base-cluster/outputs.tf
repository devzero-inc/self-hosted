output "vpc_name" {
  value = module.vpc.vpc_network_name
}

output "gke_cluster_name" {
  value = resource.google_container_cluster.gke_cluster.name
}

output "derp_ip" {
  value = length(module.derp) > 0 ? module.derp[0].derp_ip : null
}

output "derp_ssh_private_key" {
  value = length(module.derp) > 0 ? module.derp[0].private_key_pem : null
  description = "Private key to SSH into the DERP server"
  sensitive   = true
}
