output "derp_server_elastic_ip" {
  value = var.public_derp ? local.create_eip ? aws_eip.derp_eip[0].public_ip : data.aws_eip.existing[0].public_ip : null
}

output "derp_server_private_ip" {
  value = aws_instance.derp_server.private_ip
}

output "derp_server_public_ip" {
  value = aws_instance.derp_server.public_ip
}

output "subnet_id" {
  value = var.subnet_id
}

output "security_group_id" {
  value = local.security_group_id
}
