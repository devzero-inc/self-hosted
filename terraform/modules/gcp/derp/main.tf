resource "google_compute_instance" "derp_server" {
  name         = "derp-server"
  machine_type = var.instance_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnet
    access_config {
      nat_ip = var.public_derp ? google_compute_address.derp_static_ip[0].address : null
    }
  }

  metadata_startup_script = templatefile("${path.module}/derp-init.tpl", {
    hostname    = var.hostname
    public_derp = var.public_derp
  })

  tags = ["derp-server"]
}

################################################################################
# Static IP (Equivalent to AWS EIP)
################################################################################
resource "google_compute_address" "derp_static_ip" {
  count   = var.public_derp ? 1 : 0
  name    = "derp-static-ip"
  region  = var.region
  project = var.project_id
}

################################################################################
# Firewall Rules (Equivalent to AWS Security Group)
################################################################################
resource "google_compute_firewall" "derp_firewall" {
  name    = "derp-firewall"
  network = var.network
  project = var.project_id

  allow {
    protocol = "udp"
    ports    = ["3478"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }

  source_ranges = var.ingress_cidr_blocks
}