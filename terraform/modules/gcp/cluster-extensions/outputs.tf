output "workload_identity" {
  description = "Workload Identity Service Account Mapping"
  value       = module.gke_workload_identity
}

output "persistent_disk_storage_class" {
  description = "Default Persistent Disk Storage Class"
  value       = kubernetes_storage_class.pd_standard.metadata[0].name
}

output "filestore_instance" {
  description = "Filestore instance information"
  value       = var.enable_filestore ? google_filestore_instance.filestore[0] : null
}
