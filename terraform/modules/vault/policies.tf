locals {
  vault_kubernetes_writer_role               = "customer-secret-writer"
  vault_kubernetes_reader_role               = "customer-secret-reader"
  vault_kubernetes_auth_backend_manager_role = "auth-backend-manager"
}

resource "vault_policy" "auth_backend_manager" {
  name   = local.vault_kubernetes_auth_backend_manager_role
  policy = <<-EOT
  # Manage auth backends
  # https://developer.hashicorp.com/vault/api-docs/system/auth#enable-auth-method
  path "sys/auth" {
    capabilities = ["read"]
  }

  path "sys/auth/+" {
    capabilities = ["create", "read", "update", "delete", "sudo"]
  }

  # Manage policies
  # https://developer.hashicorp.com/vault/api-docs/system/policies#create-update-acl-policy
  path "sys/policies/acl/+" {
    capabilities = ["create", "update", "delete"]
  }

  # Manage kubernetes auth backends
  # https://developer.hashicorp.com/vault/api-docs/secret/kubernetes#write-configuration
  path "auth/+/config" {
    capabilities = ["create", "read", "update", "delete"]
  }

  # Manage kubernetes auth backend roles
  # https://developer.hashicorp.com/vault/api-docs/secret/kubernetes#create-role
  path "auth/+/role/customer-secret-reader" {
    capabilities = ["create", "read", "update", "delete"]
  }
  EOT
}

# Ref: https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2
# Ref: https://developer.hashicorp.com/vault/docs/concepts/policies
resource "vault_policy" "customer_secret_reader" {
  # Keep the policy with the same name of the role to ease debugging
  name = local.vault_kubernetes_reader_role

  policy = <<-EOT
  # This policy is managed by Terraform.
  # In place editing this file will be overwritten by next terraform run.

  ## START User level secrets
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/secrets/+" {
    capabilities = ["read"]
  }

  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/secrets/+/+" {
    capabilities = ["read"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows reading secret data and nothing else on path devzero/data/devzero/users/USER_ID/SECRET_NAME
  path "devzero/data/devzero/users/+/+" {
    capabilities = ["read"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows reading secret data and nothing else on path devzero/data/devzero/users/USER_ID/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/users/+/+/+" {
    capabilities = ["read"]
  }
  ## END User level secrets

  ## START User dz-managed level secrets
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/+/dz-managed-secrets/+" {
    capabilities = ["read"]
  }

  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/+/dz-managed-secrets/+/+" {
    capabilities = ["read"]
  }
  ## END User dz-managed level secrets


  ## START Organization level secrets
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/secrets/+" {
    capabilities = ["read"]
  }

  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/secrets/+/+" {
    capabilities = ["read"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/SECRET_NAME
  path "devzero/data/devzero/orgs/+/+" {
    capabilities = ["read"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/+/+" {
    capabilities = ["read"]
  }
  ## END Organization level secrets

  ## START Organization dz-managed level secrets
  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/dz-managed-secrets/+" {
    capabilities = ["read"]
  }

  # Allows reading secret data and nothing else on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/dz-managed-secrets/+/+" {
    capabilities = ["read"]
  }
  ## END Organization dz-managed level secrets
  EOT
}

# Ref: https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2
# Ref: https://developer.hashicorp.com/vault/docs/concepts/policies
resource "vault_policy" "customer_secret_writer" {
  # Keep the policy with the same name of the role to ease debugging
  name = local.vault_kubernetes_writer_role

  policy = <<-EOT
  # This policy is managed by Terraform.
  # In place editing this file will be overwritten by next terraform run.

  ## START User level secrets
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/secrets/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/secrets/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/users/secrets/+" {
    capabilities = ["delete"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/users/secrets/+/+" {
    capabilities = ["delete"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/users/USER_ID/SECRET_NAME
  path "devzero/data/devzero/users/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/users/USER_ID/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/users/+/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows complete deletion of secrets on path devzero/data/devzero/users/USER_ID/SECRET_NAME
  path "devzero/metadata/devzero/users/+/+" {
    capabilities = ["delete"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows complete deletion of secrets on path devzero/data/devzero/users/USER_ID/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/users/+/+/+" {
    capabilities = ["delete"]
  }
  ## END User level secrets

  ## START User dz-managed level secrets

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/+/dz-managed-secrets/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/users/+/dz-managed-secrets/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/users/+/dz-managed-secrets/+" {
    capabilities = ["delete"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/users/USER_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/users/+/dz-managed-secrets/+/+" {
    capabilities = ["delete"]
  }
  ## END User dz-managed level secrets

  ## START Organization level secrets
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path  devzero/data/devzero/orgs/ORG_ID/secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/secrets/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path  devzero/data/devzero/orgs/ORG_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/secrets/+/+" {
    capabilities = ["create", "update", "patch"]
  }

   # Allows complete deletion of secrets on path   devzero/data/devzero/orgs/ORG_ID/secrets/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/secrets/+" {
    capabilities = ["delete"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/secrets/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/secrets/+/+" {
    capabilities = ["delete"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/SECRET_NAME
  path "devzero/data/devzero/orgs/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/+" {
    capabilities = ["delete"]
  }

  # TODO: Remove this block https://devinfra.atlassian.net/browse/BE-41
  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/+/+" {
    capabilities = ["delete"]
  }
  ## END Organization level secrets


  ## START Organization dz-managed level secrets

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/data/devzero/orgs/+/dz-managed-secrets/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows managing secret data, but not reading, deleting versions, or listing secrets on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/data/devzero/orgs/+/dz-managed-secrets/+/+" {
    capabilities = ["create", "update", "patch"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/dz-managed-secrets/+" {
    capabilities = ["delete"]
  }

  # Allows complete deletion of secrets on path devzero/data/devzero/orgs/ORG_ID/dz-managed-secrets/NAMESPACE/SECRET_NAME
  path "devzero/metadata/devzero/orgs/+/dz-managed-secrets/+/+" {
    capabilities = ["delete"]
  }
  ## END Organization dz-managed level secrets
  EOT
}
