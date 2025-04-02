output "derp_ip" {
  value = local.ip_address
}

output "private_key_pem" {
  value       = tls_private_key.ssh_key.private_key_pem
  description = "Private key to SSH into the DERP server"
  sensitive   = true
}
