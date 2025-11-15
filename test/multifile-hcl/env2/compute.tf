# Compute resources - scaled up for env2
resource "google_compute_instance" "web" {
  name         = "web-server-env2"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-11"
      size  = 50
    }
  }

  network_interface {
    network = google_compute_network.main.name
  }

  labels = {
    environment = "env2"
    module      = "compute"
    role        = "web"
    tier        = "production"
  }

  tags = ["env2", "web", "managed", "scaled"]
}

# Add app server
resource "google_compute_instance" "app" {
  name         = "app-server-env2"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-11"
      size  = 50
    }
  }

  network_interface {
    network = google_compute_network.main.name
  }

  labels = {
    environment = "env2"
    module      = "compute"
    role        = "app"
    tier        = "production"
  }

  tags = ["env2", "app", "managed", "scaled"]
}
