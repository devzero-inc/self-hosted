terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}