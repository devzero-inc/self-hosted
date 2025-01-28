resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "${var.name}.vpn.ca"
    organization = var.name
  }
  validity_period_hours = 9528
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

resource "aws_acm_certificate" "ca" {
  private_key      = tls_private_key.ca.private_key_pem
  certificate_body = tls_self_signed_cert.ca.cert_pem

}

resource "aws_ssm_parameter" "vpn_ca_key" {
  name        = "/${var.name}/acm/vpn/ca_key"
  description = "VPN CA key"
  type        = "SecureString"
  value       = tls_private_key.ca.private_key_pem
}

resource "aws_ssm_parameter" "vpn_ca_cert" {
  name        = "/${var.name}/acm/vpn/ca_cert"
  description = "VPN CA cert"
  type        = "SecureString"
  value       = tls_self_signed_cert.ca.cert_pem

}

resource "aws_acm_certificate" "server" {
  private_key       = tls_private_key.server.private_key_pem
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem
  subject {
    common_name  = "${var.name}.vpn.server"
    organization = var.name
  }

  dns_names = var.additional_server_dns_names

}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem      = tls_cert_request.server.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 9528
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_ssm_parameter" "vpn_server_key" {
  name        = "/${var.name}/acm/vpn/server_key"
  description = "VPN server key"
  type        = "SecureString"
  value       = tls_private_key.server.private_key_pem
}

resource "aws_ssm_parameter" "vpn_server_cert" {
  name        = "/${var.name}/acm/vpn/server_cert"
  description = "VPN server cert"
  type        = "SecureString"
  value       = tls_locally_signed_cert.server.cert_pem
}

resource "aws_ec2_client_vpn_endpoint" "vpn-client" {
  description            = var.name
  server_certificate_arn = aws_acm_certificate.server.arn
  vpc_id                 = var.vpc_id
  security_group_ids     = concat([aws_security_group.vpn.id], var.additional_security_group_ids)
  client_cidr_block      = var.client_vpn_cidr_block
  session_timeout_hours  = 12

  split_tunnel = false
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client["root"].arn
  }
  connection_log_options {
    enabled               = false
  }

  dns_servers = [var.vpc_dns_resolver]

  depends_on = [aws_security_group.vpn]

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn-client" {
  count                  = length(var.subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  subnet_id              = var.subnet_ids[count.index]
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn-client" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  depends_on = [
    aws_ec2_client_vpn_endpoint.vpn-client,
    aws_ec2_client_vpn_network_association.vpn-client
  ]
}

resource "aws_ec2_client_vpn_route" "public" {
  count                  = length(var.subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = var.subnet_ids[count.index]

  timeouts {
    create = "10m"
  }
}

resource "aws_ec2_client_vpn_route" "routes" {
  count                  = length(var.additional_routes)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  destination_cidr_block = var.additional_routes[count.index].destination_cidr
  target_vpc_subnet_id   = var.additional_routes[count.index].subnet_id

  timeouts {
    create = "10m"
  }
}

resource "aws_s3_bucket" "vpn-config-files" {
  bucket        = "${lower(var.name)}-vpn-config-files"
  force_destroy = true
  tags = {
    Name = "${lower(var.name)}-vpn-config-files"
  }
}

resource "aws_s3_bucket_public_access_block" "vpn-config-files" {
  bucket                  = aws_s3_bucket.vpn-config-files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "vpn-config-files" {
  bucket = aws_s3_bucket.vpn-config-files.id
  policy = data.aws_iam_policy_document.vpn-config-files.json
}

data "aws_iam_policy_document" "vpn-config-files" {
  statement {
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      "arn:aws:s3:::${lower(var.name)}-vpn-config-files",
      "arn:aws:s3:::${lower(var.name)}-vpn-config-files/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_security_group" "vpn" {
  name        = "${var.name}-vpn-security-group"
  description = "${var.name}-vpn-security-group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-vpn-security-group"
  }
}

resource "tls_private_key" "client" {
  for_each  = var.vpn_client_list
  algorithm = "RSA"
}

resource "tls_cert_request" "client" {
  for_each        = var.vpn_client_list
  private_key_pem = tls_private_key.client[each.value].private_key_pem
  subject {
    common_name  = each.value
    organization = var.name
  }
}

resource "tls_locally_signed_cert" "client" {
  for_each              = var.vpn_client_list
  cert_request_pem      = tls_cert_request.client[each.value].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 9528
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "aws_acm_certificate" "client" {
  for_each          = var.vpn_client_list
  private_key       = tls_private_key.client[each.value].private_key_pem
  certificate_body  = tls_locally_signed_cert.client[each.value].cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
  tags = {
    Tier         = "Private"
    CostType     = "AlwaysCreated"
    BackupPolicy = "n/a"
  }
}

resource "aws_s3_object" "vpn-config-file" {
  for_each               = var.vpn_client_list
  bucket                 = aws_s3_bucket.vpn-config-files.id
  server_side_encryption = "aws:kms"
  key                    = "${each.value}-${lower(var.name)}.ovpn"
  content_base64 = base64encode(<<-EOT
client
dev tun
proto ${aws_ec2_client_vpn_endpoint.vpn-client.transport_protocol}
remote ${aws_ec2_client_vpn_endpoint.vpn-client.id}.prod.clientvpn.${var.region}.amazonaws.com ${aws_ec2_client_vpn_endpoint.vpn-client.vpn_port}
remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3

<ca>
${aws_ssm_parameter.vpn_ca_cert.value}
</ca>

reneg-sec 0

<cert>
${aws_ssm_parameter.vpn_client_cert[each.value].value}
</cert>

<key>
${aws_ssm_parameter.vpn_client_key[each.value].value}
</key>
    EOT
  )
}

resource "aws_ssm_parameter" "vpn_client_key" {
  for_each    = var.vpn_client_list
  name        = "/${var.name}/acm/vpn/${each.value}_client_key"
  description = "VPN ${each.value} client key"
  type        = "SecureString"
  value       = tls_private_key.client[each.value].private_key_pem
  tags = {
    Name         = "VPN ${each.value} client key imported in AWS ACM"
    Tier         = "Private"
    CostType     = "AlwaysCreated"
    BackupPolicy = "n/a"
  }
}

resource "aws_ssm_parameter" "vpn_client_cert" {
  for_each    = var.vpn_client_list
  name        = "/${var.name}/acm/vpn/${each.value}_client_cert"
  description = "VPN ${each.value} client cert"
  type        = "SecureString"
  value       = tls_locally_signed_cert.client[each.value].cert_pem
  tags = {
    Name         = "VPN ${each.value} client cert imported in AWS ACM"
    Tier         = "Private"
    CostType     = "AlwaysCreated"
    BackupPolicy = "n/a"
  }
}
