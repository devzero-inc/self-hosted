output "addons" {
  value = module.eks_blueprints_addons
}

output "efs" {
  value = var.enable_efs ? module.efs[0] : null
}

output "ebs_csi_driver_irsa" {
  value = module.ebs_csi_driver_irsa
}