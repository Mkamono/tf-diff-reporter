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

# Test case: count で条件分岐 - env1 では backup 無効
locals {
  env          = "env1"
  enable_backup = false
  enable_https = false
  replica_count = 1
}

# Primary Cloud SQL instance
resource "google_sql_database_instance" "primary" {
  name = "db-primary-${local.env}"

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = local.enable_backup
    }
  }

  labels = {
    env = local.env
  }
}

# Backup instances - only created if backup is enabled
resource "google_sql_database_instance" "backup" {
  count = local.enable_backup ? 1 : 0
  name  = "db-backup-${local.env}"

  settings {
    tier = "db-f1-micro"
  }

  labels = {
    env  = local.env
    type = "backup"
  }
}

# HTTPS listener - only enabled in env2
resource "google_compute_ssl_certificate" "default" {
  count       = local.enable_https ? 1 : 0
  name        = "cert-${local.env}"
  certificate = "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
  private_key = "-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n-----END RSA PRIVATE KEY-----"

  labels = {
    env = local.env
  }
}

# Replica instances - count で複数作成
resource "google_compute_instance" "replicas" {
  count        = local.replica_count
  name         = "replica-${count.index + 1}-${local.env}"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  labels = {
    env   = local.env
    index = count.index + 1
    type  = "replica"
  }
}

# Storage buckets - conditional creation based on env
resource "google_storage_bucket" "data" {
  count         = local.enable_backup ? 1 : 0
  name          = "backup-data-${local.env}"
  location      = "US"
  storage_class = "NEARLINE"

  labels = {
    env  = local.env
    type = "backup"
  }
}
