output "vpn_gateway" {
  description = "The created VPN Gateway"
  value       = google_compute_vpn_gateway.vpn_gateway.name
}

output "vpn_tunnel" {
  description = "The created VPN Tunnel"
  value       = google_compute_vpn_tunnel.vpn_tunnel.name
}

output "vpn_certificate" {
  description = "The VPN Certificate created"
  value       = google_certificate_manager_certificate.vpn_cert.name
}