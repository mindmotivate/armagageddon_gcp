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

###### asia subnet
resource "google_compute_subnetwork" "malgus_asia_subnet" {
  name          = var.subnet_asia
  network       = google_compute_network.hq_vpc.self_link
  ip_cidr_range = var.asia_cidr_range
  private_ip_google_access = true
  region        = var.region_2
}





# Instance in Europe HQ subnet
resource "google_compute_instance" "hq_instance" {
  name         = "europe-instance"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 10
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.hq_vpc.self_link
    subnetwork = google_compute_subnetwork.hq_subnet.self_link


access_config {
      // Ephemeral public IP
    }

}
  tags = ["http-server"]

  metadata_startup_script = "${file("${path.module}/startup.sh")}"
}




# Instance in Asia subnet
resource "google_compute_instance" "asia_instance" {
  name         = "asia-instance"
  machine_type = "e2-medium"  # Adjust machine type as needed
  zone         = "asia-southeast1-b"  # Adjust zone as needed

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"  # Windows Server 2019 image
      size  = 50
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.hq_vpc.self_link  # Reference the asia VPC
    subnetwork = google_compute_subnetwork.malgus_asia_subnet.self_link  # Reference the asia subnet

    access_config {
      // Ephemeral public IP
    }
  }
  tags = ["http-server", "rdp-enabled"]
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


############################RDP##########################################
resource "google_compute_firewall" "europe_rdp" {
  name        = "europe-rdp"
  network     = google_compute_network.hq_vpc.self_link
  description = "Allow RDP traffic from any source"
  #direction   = "INGRESS"
  #priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"] # add asia's ip range
  
  target_tags = ["rdp-enabled"]
}






# Global Address for HQ to Remote VPC Peering
resource "google_compute_global_address" "hq_to_remote_vpc_global_address" {
  name          = var.hq-to-remote-address
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.hq_vpc.id
}

# Network Peering: Remote to HQ
resource "google_compute_network_peering" "remote_to_hq_peer" {
  name         = var.remote_to_hq_peer
  network      = google_compute_network.malgus_americas_vpc.self_link
  peer_network = google_compute_network.hq_vpc.self_link
}

# Auto-created Network for Europe Peering
resource "google_compute_network" "eu_peer1_vpcn_network" {
  name                    = "europe-peering-net"
  auto_create_subnetworks = "true"
}

# Auto-created Network for Americas Peering
resource "google_compute_network" "americas_peer1_vpc_network" {
  name                    = "americas-peering-net"
  auto_create_subnetworks = "true"
}















###########################VPN GATEWAY##########################################

# Gateway (VPN Gateway):
resource "google_compute_vpn_gateway" "europe_vpn_gateway" {
    name        = "europe-vpn-gateway"
    network     = google_compute_network.hq_vpc.id
    region      = var.hq_region
    depends_on  = [google_compute_subnetwork.hq_subnet]
}

############################STATIC IP##########################################

# IP Birth (Reserved Static IP Address):
resource "google_compute_address" "eu_static_ip" {
    name   = "region-1-static-ip"
    region = var.hq_region
}


############################ESP FORWARDING##########################################


# Forwarding Rule for ESP traffic
resource "google_compute_forwarding_rule" "rule_esp_fw" {
  name        = "rule-esp-europe"
  region      = var.hq_region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.eu_static_ip.address
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}


############################UDP500##########################################


# Forwarding Rule for UDP Port 500 traffic
resource "google_compute_forwarding_rule" "rule_udp_500" {
  name        = "rule-udp500-europe"
  region      = var.hq_region
  ip_protocol = "UDP"
  ip_address  = google_compute_address.eu_static_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

############################UDP4500##########################################


# Forwarding Rule for UDP Port 4500 traffic
resource "google_compute_forwarding_rule" "rule_udp_4500" {
  name        = "rule-udp4500-europe"
  region      = var.hq_region
  ip_protocol = "UDP"
  ip_address  = google_compute_address.eu_static_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}




#########################EUROPE TUNNEL##########################################
# Tunnel from Europe to Asia
resource "google_compute_vpn_tunnel" "europe_to_asia_tunnel" {
  name               = "europe-to-asia-tunnel"
  target_vpn_gateway = google_compute_vpn_gateway.europe_vpn_gateway.self_link
  peer_ip            = google_compute_address.asia_static_ip.address
  shared_secret      = "malgusclan"  # Replace with your shared secret
  ike_version        = 2
  local_traffic_selector  = ["10.105.10.0/24"]  # Replace with Europe VPC subnet
  remote_traffic_selector = ["192.168.2.0/24"]    # Replace with Asia VPC subnet

  depends_on = [
    google_compute_forwarding_rule.rule_esp_fw,
    google_compute_forwarding_rule.rule_udp_500,
    google_compute_forwarding_rule.rule_udp_4500
  ]
}



/*
############################ROUTE##########################################
# Next Hop to Final Destination in Asia
resource "google_compute_route" "route_to_asia" {
  name           = "route-to-asia"
  network        = google_compute_network.hq_vpc.id
  dest_range     = "192.168.2.0"  # Replace with Asia VPC subnet
  priority       = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.europe_to_asia_tunnel.id

  depends_on = [google_compute_vpn_tunnel.europe_to_asia_tunnel]
}
*/

############################INTERNAL##########################################
# Internal Traffic Firewall Rule for Europe
resource "google_compute_firewall" "allow_internal_traffic_europe" {
  name    = "allow-internal-traffic-europe"
  network = google_compute_network.hq_vpc.id

  allow {
    protocol = "all"
  }

  source_ranges = ["192.168.2.0/24"]  # Replace with Asia VPC subnet
  description   = "Allow all internal traffic from Asia VPC"
}


























############################ASIA TUNNEL##########################################
# Tunnel from Europe to Asia

# Gateway (VPN Gateway):
resource "google_compute_vpn_gateway" "asia_vpn_gateway" {
    name        = "asia-vpn-gateway"
    network     = google_compute_network.hq_vpc.id
    region      = var.region_2
    depends_on  = [google_compute_subnetwork.malgus_asia_subnet]
}


############################ STATIC IP CREATION ##########################################
# Static IP
resource "google_compute_address" "asia_static_ip" {
    name   = "region-2-static-ip"
    region = var.region_2
}



############################ ESP FORWARDING ##########################################
# Forwarding Rule for ESP traffic
resource "google_compute_forwarding_rule" "rule_esp" {
  name        = "rule-esp"
  region      = var.region_2
  ip_protocol = "ESP"
  ip_address  = google_compute_address.asia_static_ip.address
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
  # project = var.project_id
}


############################ UDP FORWARDING 500 ##########################################
# Forwarding Rule for UDP Port 500 traffic
resource "google_compute_forwarding_rule" "rule_udp500" {
  name        = "rule-udp500"
  region      = var.region_2
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_static_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}



############################ UDP FORWARDING 4500 ##########################################
# Forwarding Rule for UDP Port 4500 traffic
resource "google_compute_forwarding_rule" "rule_udp4500" {
  name        = "rule-udp4500"
  region      = var.region_2
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_static_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}





############################ ASIA TO HQ TUNNEL ##########################################


# Tunnel remote asia to europe hq
resource "google_compute_vpn_tunnel" "asia_to_europe_tunnel" {
  name               = "asia-to-europe-tunnel"
  target_vpn_gateway = google_compute_vpn_gateway.asia_vpn_gateway.self_link
  peer_ip            = google_compute_address.eu_static_ip.address
  shared_secret      = "malgusclan"  # Replace with your shared secret
  ike_version        = 2
  local_traffic_selector  = ["192.168.2.0/24"]  # Replace with Asia VPC subnet
  remote_traffic_selector = ["10.105.10.0/24"]  # Replace with Europe VPC subnet

  depends_on = [
    google_compute_forwarding_rule.rule_esp,
    google_compute_forwarding_rule.rule_udp500,
    google_compute_forwarding_rule.rule_udp4500
  ]
}
