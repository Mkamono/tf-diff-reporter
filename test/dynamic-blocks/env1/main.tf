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

# Test case: dynamic blocks で複数のネットワークルールを生成
locals {
  env = "env1"
  ingress_rules = [
    {
      protocol = "tcp"
      ports    = ["22"]
      sources  = ["0.0.0.0/0"]
    },
    {
      protocol = "tcp"
      ports    = ["80"]
      sources  = ["0.0.0.0/0"]
    },
  ]
  egress_rules  = [
    {
      protocol = "tcp"
      ports    = ["443"]
    },
  ]
}

# Firewall with dynamic ingress rules
resource "google_compute_firewall" "ingress" {
  name      = "fw-ingress-${local.env}"
  network   = "default"
  direction = "INGRESS"

  dynamic "allow" {
    for_each = local.ingress_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "source_ranges" {
    for_each = local.ingress_rules
    content {
      value = source_ranges.value.sources[0]
    }
  }

  labels = {
    env = local.env
  }
}

# Firewall with dynamic egress rules
resource "google_compute_firewall" "egress" {
  name      = "fw-egress-${local.env}"
  network   = "default"
  direction = "EGRESS"

  dynamic "allow" {
    for_each = local.egress_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  labels = {
    env = local.env
  }
}

# Cloud Run service with dynamic environment variables
locals {
  env_vars = {
    LOG_LEVEL = "info"
    DEBUG     = "false"
  }
}

resource "google_cloud_run_service" "api" {
  name     = "api-${local.env}"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/my-project/api:v1"

        dynamic "env" {
          for_each = local.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }

  labels = {
    env = local.env
  }
}
