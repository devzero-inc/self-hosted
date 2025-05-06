################################################################################
# AKS Cluster Details
################################################################################

data "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

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
# External Secrets Operator
################################################################################

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "external-secrets"
  namespace  = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.13"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

################################################################################
# Azure Files Backing Resources
################################################################################

resource "azurerm_storage_account" "azure_files" {
  count = var.enable_azure_files ? 1 : 0

  name                     = lower(replace("${var.cluster_name}files", "[^a-z0-9]", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = var.tags
}

resource "azurerm_storage_share" "efs_etcd_share" {
  count               = var.enable_azure_files ? 1 : 0
  name                = "efs-etcd"
  storage_account_name = azurerm_storage_account.azure_files[0].name
  quota               = 100
}

resource "kubernetes_secret" "azure_files_secret" {
  count = var.enable_azure_files ? 1 : 0

  metadata {
    name      = "azure-files-secret"
    namespace = "default"
  }

  data = {
    azurestorageaccountname = azurerm_storage_account.azure_files[0].name
    azurestorageaccountkey  = azurerm_storage_account.azure_files[0].primary_access_key
  }

  type = "Opaque"
}

################################################################################
# Azure Files CSI StorageClass (named as `efs-etcd`)
################################################################################

resource "kubernetes_storage_class" "azurefiles_csi" {
  count = var.enable_azure_files ? 1 : 0

  metadata {
    name = "efs-etcd"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "file.csi.azure.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    skuName        = "Standard_LRS"
    secretName     = "azure-files-secret"
    secretNamespace = "default"
    shareName      = "efs-etcd"
  }
}
