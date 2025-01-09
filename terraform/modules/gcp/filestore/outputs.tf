output "filestore_instance_name" {
  description = "The name of the created Filestore instance"
  value       = google_filestore_instance.filestore.name
}

output "filestore_instance_id" {
  description = "The ID of the created Filestore instance"
  value       = google_filestore_instance.filestore.id
}