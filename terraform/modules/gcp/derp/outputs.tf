output "derp_server_ip" {
  description = "DERP Server Public IP (if enabled)"
  value       = var.public_derp ? google_compute_address.derp_static_ip[0].address : null
}

output "derp_server_private_ip" {
  description = "DERP Server Private IP"
  value       = google_compute_instance.derp_server.network_interface[0].network_ip
}