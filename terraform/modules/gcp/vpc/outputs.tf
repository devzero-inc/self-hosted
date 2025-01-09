output "vpc_subnets" {
  value = [for subnets in google_compute_subnetwork.private_subnets : subnets.name]
}

output "vpc_name" {
    value = google_compute_network.vpc.name
}