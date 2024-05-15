# VPC and Subnetwork for Europe Headquarters
resource "google_compute_network" "hq_vpc" {
  name                    = "malgus-eu-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1460
}

resource "google_compute_subnetwork" "hq_subnet" {
  name          = var.subnet_hq
  network       = google_compute_network.hq_vpc.self_link
  ip_cidr_range = var.hq_cidr_range
  region        = var.hq_region
}



# Firewall Rule to Allow Port 80 Traffic in Europe
resource "google_compute_firewall" "allow_port_80_eu" {
  project = var.project_id
  name    = "allow-port-80-eu"
  network = google_compute_network.hq_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
}


# Instance in Europe HQ subnet
resource "google_compute_instance" "hq_instance" {
  name         = "europe-instance"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 50
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.hq_vpc.name
    subnetwork = google_compute_subnetwork.hq_subnet.name

access_config {
      // Ephemeral public IP
    }

}
  tags = ["http-server"]

  metadata_startup_script = "${file("${path.module}/startup.sh")}"
}


# Output Information using your naming convention
output "hq_vpc_public_ip" {
  value = google_compute_instance.hq_instance.network_interface[0].access_config[0].nat_ip  # Assuming public IP is desired
}

output "hq_vpc_name" {
  value = google_compute_network.hq_vpc.name
}

output "hq_subnet_name" {
  value = google_compute_subnetwork.hq_subnet.name
}

output "hq_instance_internal_ip" {
  value = google_compute_instance.hq_instance.network_interface.0.network_ip
}

output "clickable_web_link" {
  value = format("http://%s", google_compute_instance.hq_instance.network_interface.0.access_config.0.nat_ip)
}


# Output with formatted URL
output "clickable_web_link2" {
  value = format("http://%s", google_compute_instance.hq_instance.network_interface.0.access_config.0.nat_ip)
}