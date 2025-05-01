terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.106.1, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

locals {
  public_subnet_names  = ["public-subnet-1"]
  private_subnet_names = ["private-subnet-1"]

  calculated_public_subnets_cidrs  = ["10.240.1.0/24"]
  calculated_private_subnets_cidrs = ["10.240.101.0/24"]
}

data "azurerm_client_config" "current" {}

################################################################################
# VNET (updated to Azure/network/azurerm v5.3.0 with extended support)
################################################################################

module "vnet" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"

  resource_group_name = var.resource_group_name
  use_for_each        = false

  vnet_name      = "${var.cluster_name}-vnet"
  address_space  = var.cidr

  subnet_names   = concat(local.public_subnet_names, local.private_subnet_names)
  subnet_prefixes = concat(
    local.calculated_public_subnets_cidrs,
    local.calculated_private_subnets_cidrs
  )

  subnet_enforce_private_link_endpoint_network_policies = {
    for s in concat(local.public_subnet_names, local.private_subnet_names) : s => false
  }

  tags = var.tags
}


################################################################################
# AKS CLUSTER (updated to valid parameters for v9.4.1 module)
################################################################################

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.4.1"

  resource_group_name = var.resource_group_name
  location            = var.location
  cluster_name        = var.cluster_name
  kubernetes_version  = var.cluster_version

  vnet_subnet_id                   = module.vnet.vnet_subnets[0]
  network_plugin                   = "azure"
  network_policy                   = "azure"
  private_cluster_enabled          = var.enable_private_cluster
  api_server_authorized_ip_ranges = []

  identity_type = "SystemAssigned"

  rbac_aad                           = var.enable_rbac
  rbac_aad_managed                  = var.enable_rbac
  rbac_aad_admin_group_object_ids   = var.enable_rbac ? var.admin_group_object_ids : null
  role_based_access_control_enabled = var.enable_rbac

  log_analytics_workspace_enabled = true
  log_retention_in_days           = 30
  cluster_log_analytics_workspace_name       = var.cluster_log_analytics_workspace_name
  prefix                                     = var.prefix
  
  key_vault_secrets_provider_enabled                 = true
  secret_rotation_enabled                            = true
  secret_rotation_interval                           = "2m"

  agents_pool_name          = "systemnp"
  agents_size               = var.instance_type
  enable_auto_scaling       = var.enable_cluster_autoscaler
  agents_min_count          = var.enable_cluster_autoscaler ? var.min_size : null
  agents_max_count          = var.enable_cluster_autoscaler ? var.max_size : null
  agents_count              = var.enable_cluster_autoscaler ? null : var.node_count
  temporary_name_for_rotation = "rotation"
  agents_max_pods = 100

  tags = var.tags
}

################################################################################
# Azure Key Vault for Vault Auto-Unseal
################################################################################

resource "azurerm_key_vault" "vault_auto_unseal" {
  count = var.create_vault_auto_unseal_key ? 1 : 0

  name                        = "${var.cluster_name}-vault-kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 10
  enable_rbac_authorization   = true
}

resource "azurerm_key_vault_key" "vault_auto_unseal" {
  count = var.create_vault_auto_unseal_key ? 1 : 0

  name         = "${var.cluster_name}-auto-unseal"
  key_vault_id = azurerm_key_vault.vault_auto_unseal[0].id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]

  depends_on = [azurerm_key_vault.vault_auto_unseal]
}

resource "azurerm_role_assignment" "vault_key_usage" {
  count = var.create_vault_auto_unseal_key ? 1 : 0

  principal_id         = azuread_service_principal.vault[0].object_id                                                                                                                                                                         
  role_definition_name = "Key Vault Crypto User"
  scope                = azurerm_key_vault.vault_auto_unseal[0].id                                                                                                                            
}

resource "azuread_application" "vault" {                                          
  count        = var.create_vault_auto_unseal_key ? 1 : 0                                                       
  display_name = "${var.cluster_name}-vault-app"
}

resource "azuread_service_principal" "vault" {
  count      = var.create_vault_auto_unseal_key ? 1 : 0
  client_id  = azuread_application.vault[0].client_id
}

resource "azuread_application_password" "vault" {
  count        = var.create_vault_auto_unseal_key ? 1 : 0
  application_id = azuread_application.vault[0].id
  display_name   = "Vault SP Password"
  end_date_relative = "8760h"
}