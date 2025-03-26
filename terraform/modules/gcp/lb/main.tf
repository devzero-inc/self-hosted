module "gcp_lb" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "12.1.2"

  name        = var.name
  project     = var.project_id

  backends = {
    default = {
      description = "Backend service for DevZero"
      health_checks = [google_compute_health_check.default.self_link]
      groups = [{
        group = google_compute_instance_group.default.self_link
      }]
      log_config = {
        enable = true
      }
    }
  }

  url_map = "default"

  https_redirect = true

  ssl_certificates = [var.ssl_certificate_id]
}

resource "google_compute_health_check" "default" {
  name               = "${var.name}-health-check"
  check_interval_sec = var.health_check.interval
  timeout_sec        = var.health_check.timeout
  healthy_threshold  = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  http_health_check {
    port         = 80
    request_path = var.health_check.path
  }
}

resource "google_compute_instance_group" "default" {
  name        = "${var.name}-instance-group"
  project     = var.project_id
  zone        = var.zone
  description = "Instance group for Load Balancer backend"
}

resource "google_compute_global_address" "default" {
  name          = "${var.name}-global-ip"
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
}

resource "google_compute_firewall" "allow-http-https" {
  name    = "${var.name}-allow-http-https"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_dns_record_set" "lb_dns" {
  name         = var.record
  type         = "A"
  ttl          = 300
  managed_zone = var.zone_id
  rrdatas      = [google_compute_global_address.default.address]
}