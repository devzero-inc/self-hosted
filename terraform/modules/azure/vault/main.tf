resource "azurerm_key_vault" "vault_auto_unseal" {
  name                        = "${var.cluster_name}-vault-kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 10
  enable_rbac_authorization   = true
}

resource "azurerm_key_vault_key" "vault_auto_unseal" {
  name         = "${var.cluster_name}-auto-unseal"
  key_vault_id = azurerm_key_vault.vault_auto_unseal.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]

  depends_on = [azurerm_key_vault.vault_auto_unseal]
}

resource "azurerm_role_assignment" "vault_key_usage" {
  principal_id         = var.service_principal_object_id
  role_definition_name = "Key Vault Crypto User"
  scope                = azurerm_key_vault.vault_auto_unseal.id
}
