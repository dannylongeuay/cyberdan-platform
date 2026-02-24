terraform {
  required_version = ">= 1.6.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # DigitalOcean Spaces (S3-compatible) remote state backend.
  # The Spaces bucket must be created manually before running `tofu init`:
  #   doctl spaces create cyberdan-tofu-state --region nyc3
  backend "s3" {
    endpoints = {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }

    bucket = "cyberdan-tofu-state"
    key    = "infrastructure/terraform.tfstate"

    # Required by the S3 backend but unused by Spaces
    region = "us-east-1"

    # Skip AWS-specific validations
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}
