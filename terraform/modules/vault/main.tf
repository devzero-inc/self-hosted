locals {
  vault_auth_kubernetes_writer_path = "vault-csi-writer"
  vault_kubernetes_writer_service_account_name_polland = "${var.chart_prefix}-polland"
  vault_kubernetes_writer_service_account_name_backend = "${var.chart_prefix}-backend"
  vault_kubernetes_writer_service_account_namespace    = "devzero"
}


data "kubernetes_secret" "vault" {
  provider = kubernetes
  metadata {
    name      = "vault-unseal-keys"
    namespace = "devzero"
  }
}

resource "vault_mount" "devzero" {
  path        = "devzero"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_auth_backend" "kubernetes-writer" {
  type = "kubernetes"
  path = local.vault_auth_kubernetes_writer_path
}

resource "vault_kubernetes_auth_backend_config" "kubernetes-writer" {
  backend                = vault_auth_backend.kubernetes-writer.path
  kubernetes_host        = var.cluster_host
  kubernetes_ca_cert     = sensitive(base64decode(var.cluster_ca_certificate))
  disable_iss_validation = true
}

resource "vault_kubernetes_auth_backend_role" "kubernetes_writer_customersecretwriter" {
  backend                          = vault_auth_backend.kubernetes-writer.path
  role_name                        = local.vault_kubernetes_writer_role
  bound_service_account_names      = [local.vault_kubernetes_writer_service_account_name_polland, local.vault_kubernetes_writer_service_account_name_backend]
  bound_service_account_namespaces = [local.vault_kubernetes_writer_service_account_namespace]
  token_ttl                        = 3600
  token_policies = [
    vault_policy.customer_secret_writer.name,
    vault_policy.customer_secret_reader.name,
    vault_policy.auth_backend_manager.name,
  ]
  audience          = null
  alias_name_source = "serviceaccount_name"
}