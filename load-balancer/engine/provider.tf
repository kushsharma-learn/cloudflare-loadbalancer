# Plumbing. DO NOT EDIT.
terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.7, < 6.0"
    }
  }
}

# Auth: export CLOUDFLARE_API_TOKEN (locally or as a GitHub Actions secret).
# Token needs Account "Load Balancing: Monitors and Pools" + Zone
# "Load Balancers", both with Edit permission.
provider "cloudflare" {}
