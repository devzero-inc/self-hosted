data "google_kms_key_ring" "vault" {
  name     = var.vault_key_ring_name
  location = var.vault_key_ring_location
  project  = var.project_id
}

data "google_kms_crypto_key" "existing_vault_key" {
  name     = var.vault_key_ring_name
  key_ring = data.google_kms_key_ring.vault.id
}

resource "google_kms_crypto_key_iam_member" "vault" {
  crypto_key_id = data.google_kms_crypto_key.existing_vault_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.devzero_service_account}"
}

resource "google_service_account_iam_binding" "vault_wi_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.devzero_service_account}"
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[devzero/vault]"
  ]
}
