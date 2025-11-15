# Database resources - scaled up for env2
resource "google_sql_database_instance" "main" {
  name = "database-env2"

  settings {
    tier = "db-custom-2-8192"

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    location_preference {
      zone = "us-central1-a"
    }
  }

  labels = {
    environment = "env2"
    module      = "database"
    tier        = "production"
  }
}

# Firewall rules - expanded for env2
resource "google_compute_firewall" "allow_http" {
  name      = "allow-http-env2"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags = ["env2", "web", "app"]

  labels = {
    environment = "env2"
    module      = "database"
    tier        = "production"
  }
}

# Additional firewall rule for app
resource "google_compute_firewall" "allow_app" {
  name      = "allow-app-env2"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["env2", "app"]

  labels = {
    environment = "env2"
    module      = "database"
    tier        = "production"
  }
}
