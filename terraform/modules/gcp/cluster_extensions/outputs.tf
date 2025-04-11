output "filestore_instance" {
  description = "Filestore instance information"
  value       = var.enable_filestore ? google_filestore_instance.primary[0] : null
}
