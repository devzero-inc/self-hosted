# Required Inputs
project_id = "devzero-self-hosted"
location       = "us-central1-a"
prefix   = "devzero"

# Tags
tags = {
  created-by = "devzero"
}

# Enable Persistent Disk CSI Driver (like EBS)
enable_pd_csi_driver = true

# Cluster Autoscaler
enable_cluster_autoscaler        = true
cluster_autoscaler_chart_version = "9.43.2"

# Disable old default storage class (e.g., 'standard') and set 'pd-balanced' as default
disable_existing_default_storage_class = true
previous_default_storage_class_name    = "standard"

# Filestore (EFS equivalent)
enable_filestore            = true
efs_capacity_gb             = 1024
filestore_reserved_ip_range = "10.10.0.0/29"
