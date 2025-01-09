output "vpc_subnets" {
  value = module.vpc.vpc_subnets
}

# Output the Vault Service Account Email
output "vault_service_account_email" {
  value = google_service_account.vault_service_account.email
}

# Output the CryptoKey Resource Name
output "vault_crypto_key_id" {
  value = google_kms_crypto_key.vault_crypto_key.id
}
