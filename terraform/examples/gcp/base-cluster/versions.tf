terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0, < 7.0.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0.0, < 7.0.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0"
    }
  }
}
