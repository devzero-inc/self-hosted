resource "google_compute_router" "nat_router" {
  name    = "${var.prefix}-router"
  region  = var.region
  network = var.network
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name    = "${var.prefix}-nat"
  router  = google_compute_router.nat_router.name
  region  = var.region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
