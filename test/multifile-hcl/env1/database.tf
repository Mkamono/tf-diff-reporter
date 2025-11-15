# Database resources
resource "google_sql_database_instance" "main" {
  name = "database-env1"

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = false
    }

    location_preference {
      zone = "us-central1-a"
    }
  }

  labels = {
    environment = "env1"
    module      = "database"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_http" {
  name      = "allow-http-env1"
  network   = google_compute_network.main.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["env1", "web"]

  labels = {
    environment = "env1"
    module      = "database"
  }
}
