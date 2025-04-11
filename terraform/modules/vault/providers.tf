terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.23"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "vault" {
  address            = "https://vault.${var.domain}"
  add_address_to_env = true
  token              = data.kubernetes_secret.vault.data["root-token"]
  skip_child_token   = true
}
