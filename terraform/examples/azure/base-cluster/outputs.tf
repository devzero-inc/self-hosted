output "subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  description = "The name of the resource group used for the AKS cluster."
  value       = var.resource_group_name
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = var.cluster_name
}

output "location" {
  description = "The Azure region where the AKS cluster is deployed."
  value       = var.location
}

output "sp_client_id" {
  value       = (var.create_vault_auto_unseal_key || var.create_vpn) ? azuread_application.sp[0].client_id : null
  description = "The client ID for Vault's Azure Key Vault integration."
}

output "sp_client_secret" {
  value       = (var.create_vault_auto_unseal_key || var.create_vpn) ? azuread_application_password.sp[0].value : null
  description = "The client secret for Vault's Azure Key Vault integration."
  sensitive   = true
}

output "tenant_id" {
  value       = (var.create_vault_auto_unseal_key || var.create_vpn) ? data.azurerm_client_config.current.tenant_id : null
  description = "The Azure Tenant ID."
}

output "vault_key_name" {
  value       = var.create_vault_auto_unseal_key ? module.vault[0].vault_key_name : null
  description = "The name of the Key Vault key."
}

output "vault_keyvault_name" {
  value       = var.create_vault_auto_unseal_key ? module.vault[0].vault_keyvault_name: null
  description = "The name of the Key Vault instance."
}
