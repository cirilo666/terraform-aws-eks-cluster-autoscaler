terraform {
  required_providers {
    aws = {
      version = "4.15.1"
      source  = "hashicorp/aws"
    }
    helm = {
      version = "2.4.1"
      source  = "hashicorp/helm"
    }
  }
  required_version = ">= 1"
}
