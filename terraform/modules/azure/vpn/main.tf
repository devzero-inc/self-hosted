resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem
  subject {
    common_name  = "${var.name}.vpn.ca"
    organization = var.name
  }
  validity_period_hours = 87600
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",   # Add this for client auth
    "key_encipherment",     # Add this for VPN usage
    "client_auth",           # Ensure VPN client compatibility
    "server_auth"
  ]
}

locals {
  root_cert_data = replace(
    replace(
      replace(
        tls_self_signed_cert.ca.cert_pem,
        "-----BEGIN CERTIFICATE-----\n",
        ""
      ),
      "\n-----END CERTIFICATE-----",
      ""
    ),
    "\n",
    ""
  )
}

resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "${var.name}-vpn-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "${var.name}-vpn-gw"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vpn-gateway-config"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  vpn_client_configuration {
    address_space = [var.vpn_client_cidr]
    vpn_client_protocols = ["OpenVPN"]
    root_certificate {
      name             = "vpn-root"
      public_cert_data = local.root_cert_data
    }
    vpn_auth_types = ["Certificate"]
  }
  depends_on = [
    tls_self_signed_cert.ca
  ]
}

resource "azurerm_storage_account" "vpn_config" {
  name                     = "${lower(var.name)}vpnstorage"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "vpn_config_container" {
  name                  = "vpn-config-files"
  storage_account_name  = azurerm_storage_account.vpn_config.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "vpn_keyvault" {
  name                        = "${lower(var.name)}-vpn-kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_key_vault_access_policy" "vpn_access" {
  key_vault_id = azurerm_key_vault.vpn_keyvault.id
  tenant_id    = var.tenant_id
  object_id    = var.sp_object_id

  secret_permissions = [
    "Get", "List",  # Add "get" permission to allow secret retrieval
  ]
}

resource "azurerm_key_vault_secret" "vpn_ca_cert" {
  name         = "vpn-ca-cert"
  value        = tls_self_signed_cert.ca.cert_pem
  key_vault_id = azurerm_key_vault.vpn_keyvault.id
}

resource "azurerm_key_vault_secret" "vpn_ca_key" {
  name         = "vpn-ca-key"
  value        = tls_private_key.ca.private_key_pem
  key_vault_id = azurerm_key_vault.vpn_keyvault.id
}

resource "tls_private_key" "client" {
  for_each = var.vpn_client_list
  algorithm = "RSA"
}

resource "tls_cert_request" "client" {
  for_each        = var.vpn_client_list
  private_key_pem = tls_private_key.client[each.key].private_key_pem
  subject {
    common_name  = each.key
    organization = var.name
  }
}

resource "tls_locally_signed_cert" "client" {
  for_each              = var.vpn_client_list
  cert_request_pem      = tls_cert_request.client[each.key].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 87600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
    "server_auth"
  ]
}

resource "azurerm_key_vault_secret" "vpn_client_cert" {
  for_each    = var.vpn_client_list
  name        = "vpn-${each.key}-cert"
  value       = tls_locally_signed_cert.client[each.key].cert_pem
  key_vault_id = azurerm_key_vault.vpn_keyvault.id
}

resource "azurerm_key_vault_secret" "vpn_client_key" {
  for_each    = var.vpn_client_list
  name        = "vpn-${each.key}-key"
  value       = tls_private_key.client[each.key].private_key_pem
  key_vault_id = azurerm_key_vault.vpn_keyvault.id
}

resource "azurerm_storage_blob" "vpn_config_file" {
  for_each               = var.vpn_client_list
  name                   = "${substr(each.key, 0, 30)}-${lower(var.name)}.ovpn"
  storage_account_name   = azurerm_storage_account.vpn_config.name
  storage_container_name = azurerm_storage_container.vpn_config_container.name
  type                   = "Block"
  source_content = <<EOT
client
dev tun
proto udp
remote ${azurerm_public_ip.vpn_gateway_ip.ip_address} ${var.vpn_gateway_port}
remote-cert-tls server
verify-x509-type server
verify-x509-name "${var.name}-vpn-gw" name
tls-version-min 1.2
tls-client
auth SHA256
cipher AES-256-CBC
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
data-ciphers-fallback AES-256-CBC
persist-key
persist-tun
resolv-retry infinite
nobind
verb 4
auth-nocache
keepalive 10 120
<ca>
${azurerm_key_vault_secret.vpn_ca_cert.value}
</ca>
<cert>
${azurerm_key_vault_secret.vpn_client_cert[each.key].value}
</cert>
<key>
${azurerm_key_vault_secret.vpn_client_key[each.key].value}
</key>
EOT

  depends_on = [
    azurerm_key_vault_secret.vpn_client_cert,
    azurerm_key_vault_secret.vpn_client_key
  ]
}