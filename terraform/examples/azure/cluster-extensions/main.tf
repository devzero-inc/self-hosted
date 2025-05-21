################################################################################
# Providers
################################################################################

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

data "azurerm_client_config" "current" {}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.this.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.this.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
  }
}

################################################################################
# AKS Cluster Data
################################################################################

data "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

################################################################################
# Cluster Extensions Module (Azure parity)
################################################################################

module "cluster_extensions" {
  source = "../../../modules/azure/cluster_extensions"

  cluster_name            = var.cluster_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  enable_external_secrets = var.enable_external_secrets
  enable_azure_files      = var.enable_azure_files
  tags                    = var.tags
}