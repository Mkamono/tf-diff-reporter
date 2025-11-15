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

# Test case: for_each で複数のストレージバケットを管理
resource "google_storage_bucket" "app_buckets" {
  for_each = {
    logs   = "STANDARD"
    data   = "NEARLINE"
    backup = "COLDLINE"
  }

  name          = "app-bucket-${each.key}-env1"
  location      = "US"
  storage_class = each.value

  labels = {
    env    = "env1"
    bucket = each.key
  }
}

# Test case: for_each で複数のサービスアカウントを管理
resource "google_service_account" "services" {
  for_each = toset(["api", "worker", "scheduler"])

  account_id   = "app-${each.value}-env1"
  display_name = "App ${each.value} Service Account (env1)"
  description  = "Service account for ${each.value} in env1"
}

# Test case: for_each でネットワークタグを適用
resource "google_compute_instance" "web_servers" {
  for_each = {
    frontend-1 = "10.0.1.10"
    frontend-2 = "10.0.1.11"
  }

  name         = "web-server-${each.key}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  labels = {
    env  = "env1"
    role = "frontend"
  }

  tags = ["env1", "web"]
}
