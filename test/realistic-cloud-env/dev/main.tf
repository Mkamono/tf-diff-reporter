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
  project = "my-dev-project"
  region  = "asia-northeast1"
}

# Development Environment Configuration
# This file contains the actual resource definitions with values for dev environment

# VPC Configuration
resource "google_compute_network" "main" {
  name                    = "myapp-vpc-dev"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "myapp-gke-cluster-dev"
  location = "asia-northeast1"

  initial_node_count = 1

  network_policy {
    enabled = true
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  resource_labels = {
    environment = "dev"
    tier        = "compute"
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "myapp-db-instance-dev"
  database_version = "POSTGRES_15"
  region           = "asia-northeast1"

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 100

    backup_configuration {
      enabled  = true
      location = "asia-northeast1"
    }

    user_labels = {
      environment = "dev"
      component   = "database"
    }
  }

  labels = {
    environment = "dev"
  }
}

# Redis Instance
resource "google_redis_instance" "cache" {
  name           = "myapp-redis-dev"
  memory_size_gb = 1
  tier           = "basic"
  region         = "asia-northeast1"
  location_id    = "asia-northeast1-a"
  redis_version  = "7.0"

  labels = {
    environment = "dev"
    component   = "cache"
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "app_data" {
  name          = "myapp-data-dev-prod"
  location      = "asia-northeast1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  labels = {
    environment = "dev"
    purpose     = "app-data"
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  name     = "myapp-api-dev"
  location = "asia-northeast1"

  template {
    spec {
      containers {
        image = "gcr.io/my-project/my-api:dev-latest"

        env {
          name  = "ENVIRONMENT"
          value = "dev"
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "autoscaling.knative.dev/minScale" = "1"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  labels = {
    environment = "dev"
  }
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = "my-dev-project"
  name        = "(default)"
  location_id = "asia-northeast1"
  type        = "FIRESTORE_NATIVE"
}

# =====================================================
# Development-Only Resources
# These resources exist only in dev for testing purposes
# =====================================================

# Dev-only: Debug Logging Storage Bucket
resource "google_storage_bucket" "debug_logs" {
  name          = "myapp-debug-logs-dev"
  location      = "asia-northeast1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "dev"
    purpose     = "debug-logs"
    temporary   = "true"
  }
}

# Dev-only: Local Testing VM for integration testing
resource "google_compute_instance" "dev_test_vm" {
  name         = "myapp-dev-test-vm"
  machine_type = "e2-medium"
  zone         = "asia-northeast1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    startup-script = "echo 'Dev test VM initialized'"
  }

  labels = {
    environment = "dev"
    purpose     = "integration-testing"
    temporary   = "true"
  }

  tags = ["dev-test", "http-server"]
}

# Dev-only: Artifact Registry repository for development builds
resource "google_artifact_registry_repository" "dev_repo" {
  location      = "asia-northeast1"
  repository_id = "myapp-dev-builds"
  description   = "Development builds repository"
  format        = "DOCKER"

  labels = {
    environment = "dev"
    purpose     = "development"
  }
}

# Dev-only: Service Account for local development
resource "google_service_account" "dev_local" {
  account_id   = "myapp-dev-local-sa"
  display_name = "Dev Local Testing Service Account"
  description  = "Service account for local development and testing"
}

# Dev-only: Custom Metric for development monitoring
resource "google_monitoring_metric_descriptor" "dev_custom_metric" {
  display_name = "Dev Custom Test Metric"
  type         = "custom.googleapis.com/myapp/dev/test_metric"
  metric_kind  = "GAUGE"
  value_type   = "INT64"

  labels {
    key         = "test_label"
    value_type  = "STRING"
    description = "A test label"
  }

  unit        = "1"
  description = "A custom metric for development testing only"
}

# Dev-only: Test Log Sink for capturing debug logs
resource "google_logging_project_sink" "dev_debug_sink" {
  name            = "dev-debug-logs-sink"
  destination     = "storage.googleapis.com/${google_storage_bucket.debug_logs.name}"
  filter          = "severity=DEBUG AND resource.type=\"gke_container\""
  unique_writer_identity = true
}
