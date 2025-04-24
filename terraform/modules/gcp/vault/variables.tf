variable "vault_key_ring_name" {
  description = "Name of the KMS key ring used by Vault"
  type        = string
}

variable "vault_key_ring_location" {
  description = "Location of the KMS key ring"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "devzero_service_account" {
  description = "Service account email used by DevZero Vault"
  type        = string
}

variable "create_vault_crypto_key" {
  description = "Boolean flag to create GCP KMS"
  type        = bool
}
