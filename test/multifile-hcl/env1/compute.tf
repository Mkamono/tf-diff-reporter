# Compute resources
resource "google_compute_instance" "web" {
  name         = "web-server-env1"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-11"
      size  = 20
    }
  }

  network_interface {
    network = google_compute_network.main.name
  }

  labels = {
    environment = "env1"
    module      = "compute"
    role        = "web"
  }

  tags = ["env1", "web", "managed"]
}
