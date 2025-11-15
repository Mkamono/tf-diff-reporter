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
# env2 では HOTLINE ストレージクラスに変更
resource "google_storage_bucket" "app_buckets" {
  for_each = {
    logs   = "STANDARD"
    data   = "STANDARD"
    backup = "COLDLINE"
    archive = "ARCHIVE"
  }

  name          = "app-bucket-${each.key}-env2"
  location      = "US"
  storage_class = each.value

  labels = {
    env    = "env2"
    bucket = each.key
  }
}

# Test case: for_each でサービスアカウント数を増加（env2 では worker を2つに）
resource "google_service_account" "services" {
  for_each = toset(["api", "worker", "scheduler", "monitor"])

  account_id   = "app-${each.value}-env2"
  display_name = "App ${each.value} Service Account (env2)"
  description  = "Service account for ${each.value} in env2"
}

# Test case: for_each でインスタンス数を増加
resource "google_compute_instance" "web_servers" {
  for_each = {
    frontend-1 = "10.0.1.10"
    frontend-2 = "10.0.1.11"
    frontend-3 = "10.0.1.12"
  }

  name         = "web-server-${each.key}"
  machine_type = "e2-standard-2"
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
    env  = "env2"
    role = "frontend"
  }

  tags = ["env2", "web"]
}
