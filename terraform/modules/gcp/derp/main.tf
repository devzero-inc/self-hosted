locals {
  create_firewall_rule = var.firewall_rule_name == ""
  create_static_ip      = var.public_derp && var.existing_ip == ""

  ip_address = local.create_static_ip ? google_compute_address.derp_ip[0].address : var.existing_ip
}

# Create static external IP (EIP equivalent)
resource "google_compute_address" "derp_ip" {
  count  = local.create_static_ip ? 1 : 0
  name   = "${var.name_prefix}-derp-ip"
  region = var.region
}

# Firewall rule (Security Group equivalent)
resource "google_compute_firewall" "derp_firewall" {
  count   = local.create_firewall_rule ? 1 : 0
  name    = "${var.name_prefix}-derp-fw"
  network = var.network

  allow {
    protocol = "udp"
    ports    = ["3478"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }

  source_ranges = var.ingress_cidr_blocks

  target_tags = ["${var.name_prefix}-derp"]
  description = "Firewall rule for DERP server"

  direction = "INGRESS"

  priority = 1000
}

# Create GCP instance (EC2 equivalent)
resource "google_compute_instance" "derp_server" {
  name         = "${var.name_prefix}-derp"
  zone         = var.zone
  machine_type = var.instance_type

  tags = ["${var.name_prefix}-derp"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.volume_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork
    access_config {
      nat_ip = local.ip_address
    }
  }

  metadata_startup_script = templatefile("${path.module}/derp-init.tpl", {
    hostname    = var.hostname
    public_derp = var.public_derp
  })

  metadata = {
    ssh-keys       = "ubuntu:${tls_private_key.ssh_key.public_key_openssh}"
    enable-oslogin = "FALSE"
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  labels = var.tags
}

data "google_compute_image" "ubuntu" {
  family  = var.ubuntu_family
  project = "ubuntu-os-cloud"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
