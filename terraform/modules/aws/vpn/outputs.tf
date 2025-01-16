output "vpn_endpoint_id" {
  description = "The ID of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.vpn-client.id
}

output "vpn_security_group_id" {
  description = "The ID of the VPN security group"
  value       = aws_security_group.vpn.id
}

output "vpn_server_certificate_arn" {
  description = "The ARN of the server certificate used for the VPN"
  value       = aws_acm_certificate.server.arn
}

output "vpn_client_certificate_arns" {
  description = "Map of client certificate ARNs for the VPN"
  value       = { for k, v in aws_acm_certificate.client : k => v.arn }
}

output "vpn_ca_certificate" {
  description = "The CA certificate for the VPN"
  value       = tls_self_signed_cert.ca.cert_pem
}

output "vpn_client_config_files" {
  description = "S3 keys for VPN client configuration files"
  value       = { for k, v in aws_s3_object.vpn-config-file : k => v.key }
}

output "vpn_ca_private_key_ssm" {
  description = "SSM parameter name for the VPN CA private key"
  value       = aws_ssm_parameter.vpn_ca_key.name
}

output "vpn_ca_certificate_ssm" {
  description = "SSM parameter name for the VPN CA certificate"
  value       = aws_ssm_parameter.vpn_ca_cert.name
}

output "vpn_server_private_key_ssm" {
  description = "SSM parameter name for the VPN server private key"
  value       = aws_ssm_parameter.vpn_server_key.name
}

output "vpn_server_certificate_ssm" {
  description = "SSM parameter name for the VPN server certificate"
  value       = aws_ssm_parameter.vpn_server_cert.name
}

output "vpn_client_private_keys_ssm" {
  description = "Map of SSM parameter names for VPN client private keys"
  value       = { for k, v in aws_ssm_parameter.vpn_client_key : k => v.name }
}

output "vpn_client_certificates_ssm" {
  description = "Map of SSM parameter names for VPN client certificates"
  value       = { for k, v in aws_ssm_parameter.vpn_client_cert : k => v.name }
}

output "vpn_s3_bucket_name" {
  description = "The name of the S3 bucket storing VPN configuration files"
  value       = aws_s3_bucket.vpn-config-files.id
}

output "vpn_network_associations" {
  description = "List of network associations for the VPN"
  value       = aws_ec2_client_vpn_network_association.vpn-client[*].id
}

output "vpn_routes" {
  description = "List of routes associated with the VPN"
  value       = aws_ec2_client_vpn_route.routes[*].id
}
