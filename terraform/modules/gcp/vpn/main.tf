resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "${var.name}-vpn-gateway"
  network = var.network
  region  = var.region
}

resource "google_compute_external_vpn_gateway" "peer_gateway" {
  name       = "${var.name}-peer-gateway"
  project    = var.project_id
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  interface {
    id         = 0
    ip_address = var.peer_ip
  }
}

resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name          = "${var.name}-vpn-tunnel"
  region        = var.region
  vpn_gateway   = google_compute_vpn_gateway.vpn_gateway.id
  peer_external_gateway  = google_compute_external_vpn_gateway.peer_gateway.id
  shared_secret = var.vpn_shared_secret
}

resource "google_certificate_manager_certificate" "vpn_cert" {
  name        = "${var.name}-vpn-cert"
  project     = var.project_id
  self_managed {
    pem_private_key = var.pem_private_key
    pem_certificate = var.pem_certificate
  }
}

resource "google_compute_firewall" "vpn_firewall" {
  name    = "${var.name}-vpn-firewall"
  network = var.network
  allow {
    protocol = "esp"
  }
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  source_ranges = [var.allowed_ip_range]
}
