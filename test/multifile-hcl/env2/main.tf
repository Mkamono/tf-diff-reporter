terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-project"
  region  = "us-central1"
}

# Network configuration
resource "google_compute_network" "main" {
  name                    = "network-env2"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  labels = {
    environment = "env2"
    module      = "network"
    tier        = "production"
  }
}
