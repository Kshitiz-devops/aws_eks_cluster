terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.region

  # Optional: You can also set default tags here so they apply automatically
  default_tags {
    tags = merge(
      {
        ManagedBy = "terraform"
      },
      var.additional_tags
    )
  }
}
