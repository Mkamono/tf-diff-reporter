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
  region  = var.region
}

# Combine variables and locals
locals {
  env_prefix           = "${var.environment}-"
  common_labels        = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  enable_monitoring    = var.enable_monitoring
  monitoring_resources = local.enable_monitoring ? {
    alert-policy = {
      display_name = "High CPU Alert"
      threshold    = 80
    }
  } : {}
}

# Network resource with variables
resource "google_compute_network" "main" {
  name                    = "${local.env_prefix}vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  labels = local.common_labels
}

# Compute instances using variables and for_each
resource "google_compute_instance" "services" {
  for_each = {
    for svc in var.services : svc.name => svc
  }

  name         = "${local.env_prefix}${each.value.name}-1"
  machine_type = var.instance_config.machine_type
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image  = "debian-11"
      size   = var.instance_config.disk_size
    }
  }

  network_interface {
    network = google_compute_network.main.name
  }

  labels = merge(
    local.common_labels,
    {
      Service = each.value.name
    }
  )
}

# Monitoring resources - conditionally created based on variables
resource "google_monitoring_alert_policy" "cpu_alert" {
  for_each = local.monitoring_resources

  display_name = each.value.display_name

  conditions {
    display_name = "CPU Utilization > ${each.value.threshold}%"

    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = each.value.threshold / 100.0
    }
  }

  labels = local.common_labels
}

# Storage bucket using variables
resource "google_storage_bucket" "data" {
  name          = "${local.env_prefix}data-bucket"
  location      = "US"
  storage_class = "STANDARD"

  labels = local.common_labels
}
