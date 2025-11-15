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
  project = "my-stg-project"
  region  = "asia-northeast1"
}

# Staging Environment Configuration
# This file contains the actual resource definitions with values for stg environment

# VPC Configuration
resource "google_compute_network" "main" {
  name                    = "myapp-vpc-stg"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  labels = {
    environment = "stg"
    managed_by  = "terraform"
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "myapp-gke-cluster-stg"
  location = "asia-northeast1"

  initial_node_count = 2

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
    environment = "stg"
    tier        = "compute"
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "myapp-db-instance-stg"
  database_version = "POSTGRES_15"
  region           = "asia-northeast1"

  settings {
    tier              = "db-custom-2-8192"
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 100

    backup_configuration {
      enabled  = true
      location = "asia-northeast1"
    }

    user_labels = {
      environment = "stg"
      component   = "database"
    }
  }

  labels = {
    environment = "stg"
  }
}

# Redis Instance
resource "google_redis_instance" "cache" {
  name           = "myapp-redis-stg"
  memory_size_gb = 2
  tier           = "standard"
  region         = "asia-northeast1"
  location_id    = "asia-northeast1-a"
  redis_version  = "7.0"

  labels = {
    environment = "stg"
    component   = "cache"
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "app_data" {
  name          = "myapp-data-stg-prod"
  location      = "asia-northeast1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  labels = {
    environment = "stg"
    purpose     = "app-data"
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  name     = "myapp-api-stg"
  location = "asia-northeast1"

  template {
    spec {
      containers {
        image = "gcr.io/my-project/my-api:stg-release"

        env {
          name  = "ENVIRONMENT"
          value = "stg"
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
        "autoscaling.knative.dev/maxScale" = "20"
        "autoscaling.knative.dev/minScale" = "2"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  labels = {
    environment = "stg"
  }
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = "my-stg-project"
  name        = "(default)"
  location_id = "asia-northeast1"
  type        = "FIRESTORE_NATIVE"
}
