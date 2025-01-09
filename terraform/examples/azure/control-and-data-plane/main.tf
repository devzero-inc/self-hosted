terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  default     = null
}

resource "azurerm_resource_group" "devzero-self-hosted" {
  name     = "devzero-self-hosted"
  location = "West US"
}

resource "azurerm_kubernetes_cluster" "devzero-dsh-cluster" {
  name                = "devzero-aks-dsh"
  location            = azurerm_resource_group.devzero-self-hosted.location
  resource_group_name = azurerm_resource_group.devzero-self-hosted.name
  dns_prefix          = "devzero-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.devzero-dsh-cluster.name
}
