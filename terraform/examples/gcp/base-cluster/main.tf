locals {
  prefix = var.prefix
}

################################################################################
# PROVIDERS
################################################################################

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

################################################################################
# VPC
################################################################################
module "vpc" {
  source  = "terraform-google-modules/network/google"
  
  project_id   = var.project_id
  network_name = "${local.prefix}-vpc"

  subnets = [
    {
      subnet_name             = "${local.prefix}-gke-subnet"
      subnet_ip               = var.gke_subnet_cidr
      subnet_region           = var.region
      private_ip_google_access = false
    }
  ]

  mtu = var.mtu  # Default MTU from tfvars

  routes = [
    {
      name              = "default-route"
      description       = "Route all traffic to internet gateway"
      destination_range = "0.0.0.0/0"
      next_hop_internet = true
    }
  ]

  shared_vpc_host = var.create_vpc
}

################################################################################
# OPTIONAL: NAT Router & NAT Gateway (Only if using private nodes)
################################################################################
resource "google_compute_router" "nat_router" {
  count   = var.enable_private_nodes ? 1 : 0
  name    = "${local.prefix}-router"
  region  = var.region
  network = module.vpc.network_self_link
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  count   = var.enable_private_nodes ? 1 : 0
  name    = "${local.prefix}-nat"
  router  = google_compute_router.nat_router[0].name
  region  = var.region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

################################################################################
# GKE CLUSTER MODULE
################################################################################
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "36.1.0"

  project_id         = var.project_id
  name               = "${local.prefix}-cluster"
  region             = var.region  
  zones              = var.gke_zones  # ✅ Provide the zone explicitly for single-zone

  network            = module.vpc.network_name
  subnetwork         = module.vpc.subnets_self_links[0]

  ip_range_pods      = var.gke_cluster_ipv4_cidr
  ip_range_services  = var.gke_services_ipv4_cidr
  kubernetes_version = var.gke_master_version

  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  dns_cache                  = false

  node_pools = var.gke_node_pools  # ✅ Properly structured node pools
}
