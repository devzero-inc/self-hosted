subscription_id      = "a32b188c-43fd-4e28-8f67-c95649ab3119"
cluster_name         = "devzero"
resource_group_name  = "dev-test"
location             = "eastus"

enable_external_secrets = false
enable_azure_files      = true

tags = {
  environment = "dev"
  owner       = "devzero"
  createdBy   = "terraform"
}
