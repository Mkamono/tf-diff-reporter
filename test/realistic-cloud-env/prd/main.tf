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
  project = "my-prd-project"
  region  = "asia-northeast1"
}

# Production Environment Configuration
# This file contains the actual resource definitions with values for prd environment

# VPC Configuration
resource "google_compute_network" "main" {
  name                    = "myapp-vpc-prd"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  labels = {
    environment = "prd"
    managed_by  = "terraform"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "myapp-gke-cluster-prd"
  location = "asia-northeast1"

  initial_node_count = 3

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
    environment = "prd"
    tier        = "compute"
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "myapp-db-instance-prd"
  database_version = "POSTGRES_15"
  region           = "asia-northeast1"

  settings {
    tier              = "db-custom-4-16384"
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 100

    backup_configuration {
      enabled  = true
      location = "asia-northeast1"
    }

    user_labels = {
      environment = "prd"
      component   = "database"
    }
  }

  labels = {
    environment = "prd"
  }
}

# Redis Instance
resource "google_redis_instance" "cache" {
  name           = "myapp-redis-prd"
  memory_size_gb = 5
  tier           = "standard"
  region         = "asia-northeast1"
  location_id    = "asia-northeast1-a"
  redis_version  = "7.0"

  labels = {
    environment = "prd"
    component   = "cache"
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "app_data" {
  name          = "myapp-data-prd-prod"
  location      = "asia-northeast1"
  storage_class = "NEARLINE"

  uniform_bucket_level_access = true

  labels = {
    environment = "prd"
    purpose     = "app-data"
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  name     = "myapp-api-prd"
  location = "asia-northeast1"

  template {
    spec {
      containers {
        image = "gcr.io/my-project/my-api:release"

        env {
          name  = "ENVIRONMENT"
          value = "prd"
        }

        resources {
          limits = {
            cpu    = "2"
            memory = "1Gi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "50"
        "autoscaling.knative.dev/minScale" = "5"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  labels = {
    environment = "prd"
  }
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = "my-prd-project"
  name        = "(default)"
  location_id = "asia-northeast1"
  type        = "FIRESTORE_NATIVE"
}
