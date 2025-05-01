output "vault_sp_client_id" {
  value       = var.create_vault_auto_unseal_key ? azuread_application.vault[0].client_id : null
  description = "The client ID for Vault's Azure Key Vault integration."
}

output "vault_sp_client_secret" {
  value       = var.create_vault_auto_unseal_key ? azuread_application_password.vault[0].value : null
  description = "The client secret for Vault's Azure Key Vault integration."
  sensitive   = true
}

output "vault_tenant_id" {
  value       = var.create_vault_auto_unseal_key ? data.azurerm_client_config.current.tenant_id : null
  description = "The Azure Tenant ID."
}

output "vault_key_name" {
  value       = var.create_vault_auto_unseal_key ? azurerm_key_vault_key.vault_auto_unseal[0].name : null
  description = "The name of the Key Vault key."
}

output "vault_keyvault_name" {
  value       = var.create_vault_auto_unseal_key ? azurerm_key_vault.vault_auto_unseal[0].name : null
  description = "The name of the Key Vault instance."
}
