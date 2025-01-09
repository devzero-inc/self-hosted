locals {
  service_account_list = compact(
    concat(
      google_service_account.cluster_service_account.*.email,
      ["sa"],
    ),
  )
  // if user set var.service_accont it will be used even if var.create_service_account==true, so service account will be created but not used
  service_account = (var.service_account == "" || var.service_account == "create") && var.create_service_account ? local.service_account_list[0] : var.service_account
}

resource "random_string" "cluster_service_account_suffix" {
  upper   = false
  lower   = true
  special = false
  length  = 4
}

resource "google_service_account" "cluster_service_account" {
  count        = var.create_service_account ? 1 : 0
  project      = var.project_id
  account_id   = "tf-gke-${substr(var.cluster_name, 0, min(15, length(var.cluster_name)))}-${random_string.cluster_service_account_suffix.result}"
  display_name = "Terraform-managed service account for cluster ${var.cluster_name}"
}

resource "google_project_iam_member" "cluster_service_account-log_writer" {
  count   = var.create_service_account ? 1 : 0
  project = google_service_account.cluster_service_account[0].project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cluster_service_account[0].email}"
}

resource "google_project_iam_member" "cluster_service_account-metric_writer" {
  count   = var.create_service_account ? 1 : 0
  project = google_project_iam_member.cluster_service_account-log_writer[0].project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cluster_service_account[0].email}"
}

resource "google_project_iam_member" "cluster_service_account-monitoring_viewer" {
  count   = var.create_service_account ? 1 : 0
  project = google_project_iam_member.cluster_service_account-metric_writer[0].project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.cluster_service_account[0].email}"
}

resource "google_project_iam_member" "cluster_service_account-gcr" {
  count   = var.create_service_account && var.grant_registry_access ? 1 : 0
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cluster_service_account[0].email}"
}