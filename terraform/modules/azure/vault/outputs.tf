output "vault_key_name" {
  value       = azurerm_key_vault_key.vault_auto_unseal.name
  description = "Name of the created Key Vault key for Vault auto-unseal"
}

output "vault_keyvault_name" {
  value       = azurerm_key_vault.vault_auto_unseal.name
  description = "Name of the created Key Vault for Vault auto-unseal"
}
