output "lb_ip_address" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "firewall_rule" {
  description = "Firewall rule created for HTTP and HTTPS access"
  value       = google_compute_firewall.allow-http-https.name
}

output "lb_dns_record" {
  description = "The DNS record created for the Load Balancer"
  value       = google_dns_record_set.lb_dns.name
}
