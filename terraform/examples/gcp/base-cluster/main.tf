locals {
  calculated_public_subnets  = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : module.vpc.public_subnets
  calculated_private_subnets = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : module.vpc.private_subnets
  vpc_id                     = var.create_vpc ? module.vpc.network_id : var.vpc_id
  calculated_public_subnets_ids  = [for subnet in module.vpc.subnets : subnet.self_link]
  calculated_private_subnets_ids = [for subnet in module.vpc.subnets : subnet.self_link]
  effective_vpc_cidr_block = module.vpc.network.self_link  # Use the correct attribute
  calculated_public_subnets_cidrs  = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : []
  calculated_private_subnets_cidrs = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : []
}

################################################################################
# Precondition Checks (Same as AWS)
################################################################################
resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = !(var.create_vpc == true && length(var.availability_zones) == 0)
      error_message = "You must provide availability zones when creating a VPC."
    }

    precondition {
      condition     = !(var.create_vpc == false && var.vpc_id == null)
      error_message = "You must specify vpc_id if not creating a new VPC."
    }

    precondition {
      condition     = !(var.create_vpc == false && length(var.private_subnet_ids) == 0)
      error_message = "Private subnets must be specified if not creating a new VPC."
    }
  }
}

################################################################################
# VPC (Using Our GCP VPC Module)
################################################################################
module "vpc" {
  depends_on = [null_resource.validations]

  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"

  project_id   = var.project_id
  network_name = "${var.cluster_name}-vpc"

  subnets = [
    {
        subnet_name   = "${var.cluster_name}-public-subnet"
        subnet_ip     = local.calculated_public_subnets_cidrs[0]
        subnet_region = var.region  # ✅ Use `subnet_region` instead of `region`
        private_ip_google_access = true
    },
    {
        subnet_name   = "${var.cluster_name}-private-subnet"
        subnet_ip     = local.calculated_private_subnets_cidrs[0]
        subnet_region = var.region  # ✅ Use `subnet_region` instead of `region`
        private_ip_google_access = true
    }
  ]

  mtu = 1460  # Default MTU size in GCP

  secondary_ranges = {
    "${var.cluster_name}-public-subnet" = [
      {
        range_name    = "${var.cluster_name}-services-range"
        ip_cidr_range = "10.50.0.0/16"
      }
    ]
  }

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

resource "google_compute_router" "nat_router" {
  count      = var.enable_nat_gateway ? 1 : 0
  name       = "${var.cluster_name}-router"
  region     = var.region
  network    = module.vpc.network_self_link
  project    = var.project_id
}

resource "google_compute_router_nat" "nat" {
  count                              = var.enable_nat_gateway ? 1 : 0
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.nat_router[0].name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

################################################################################
# GKE Cluster (Using Our GCP Cluster Module)
################################################################################
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "36.1.0"

  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_self_links[0]  # Get the first subnet self-link


  remove_default_node_pool = true
  initial_node_count       = 1

  ip_range_pods     = "pods-range"  
  ip_range_services = "services-range" 
}


################################################################################
# VPN (Using Our GCP VPN Module)
################################################################################
module "vpn" {
  count  = var.create_vpn ? 1 : 0
  source = "../../../modules/gcp/vpn"

  name       = var.cluster_name
  region     = var.region
  project_id = var.project_id

  network           = module.vpc.network_name 
  peer_ip           = var.vpn_peer_ip
  vpn_shared_secret = var.vpn_shared_secret
  allowed_ip_range  = var.client_vpn_cidr_block 

  # Required fields for VPN certificates
  pem_private_key   = file("${path.module}/vpn_key.pem")  
  pem_certificate   = file("${path.module}/vpn_cert.pem")
}

################################################################################
# Cloud DNS (Equivalent to AWS Route53)
################################################################################
resource "google_dns_managed_zone" "private" {
  count       = var.use_existing_cloud_dns_zone ? 0 : 1
  name        = var.cluster_name
  dns_name    = "${var.domain}."
  description = "Private DNS Zone for ${var.cluster_name}"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = local.vpc_id
    }
  }
}

################################################################################
# DERP Server (Using Our GCP DERP Module)
################################################################################
module "derp" {
  source  = "../../../modules/gcp/derp"
  count  = var.create_derp ? 1 : 0
  project_id = var.project_id
  region     = var.region
  network    = module.vpc.network_name
  zone       = var.zone  # Ensure this variable exists
  subnet = local.calculated_private_subnets[0]
}

################################################################################
# Ingress (Google Cloud Load Balancer)
################################################################################
module "ingress" {
  count  = var.create_alb ? 1 : 0
  source = "../../../modules/gcp/lb"

  project_id = var.project_id
  name       = "${var.cluster_name}-lb"

  vpc_id      = module.vpc.network_self_link  # ✅ Corrected from `local.vpc_id`
  vpc_cidr    = local.effective_vpc_cidr_block

  ssl_certificate_id = var.create_vpn ? module.vpn[0].vpn_cert_id : null  # ✅ Use `ssl_certificate_id`
  record            = "service.${var.domain}"
  zone_id = google_dns_managed_zone.private[0].id

}

################################################################################
# Vault Auto-Unseal (Using GCP KMS)
################################################################################
resource "google_kms_key_ring" "vault" {
  count   = var.create_vault_auto_unseal_key ? 1 : 0
  name    = "${var.cluster_name}-auto-unseal"
  location = var.region
}

resource "google_kms_crypto_key" "vault_key" {
  count       = var.create_vault_auto_unseal_key ? 1 : 0
  name        = "vault-unseal-key"
  key_ring    = google_kms_key_ring.vault[0].id
  purpose     = "ENCRYPT_DECRYPT"
}
