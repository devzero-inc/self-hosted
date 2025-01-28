provider "aws" {
  region = "us-west-1"
}
variable "AWS_REGION" {
  description = "AWS region"
  type = string
  default     = ""
}
variable "ACCOUNT_ID" {
  description = "AWS account ID"
  type = string
  default     = ""
}
variable "CLUSTER_NAME" {
  description = "Cluster name"
  type = string
  default     = ""
}
variable "create_local_files" {
  description = "Whether to create local files with AWS permissions"
  type = bool
  default = false
}

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "${local.tpl_vars.CLUSTER_NAME}-test-user"
  force_destroy = true

  password_reset_required = false

  policy_arns = [for set in module.permission_sets : set.arn]
}

locals {
  tpl_vars = {
    AWS_REGION   = var.AWS_REGION
    ACCOUNT_ID   = var.ACCOUNT_ID
    CLUSTER_NAME = var.CLUSTER_NAME
  }

  permissions_data = yamldecode(templatefile("${path.module}/permissions.yaml", local.tpl_vars))
  vpc_permissions     = local.permissions_data["vpc"]
  cluster_permissions = local.permissions_data["cluster"]
  efs_permissions     = local.permissions_data["efs"]

  permission_sets = [
    ["extra", "debug-permissions"], # This is usually only required when debugging permissions. Not for general use.
    ["vpc", "creation-permissions"],
    ["vpc", "deletion-permissions"],
    ["cluster", "creation-permissions"],
    ["cluster", "deletion-permissions"],
    ["efs", "creation-permissions"],
    ["efs", "deletion-permissions"],
  ]
}

# TODO: This could be improved to increase readability
module "permission_sets" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-policy"
  for_each = {for set in local.permission_sets : "${set[0]}-${set[1]}" => [set[0], set[1]]}

  name        = "${local.tpl_vars.CLUSTER_NAME}-${each.key}"
  path        = "/"
  description = "${local.tpl_vars.CLUSTER_NAME}-${each.key}"

  policy = jsonencode(local.permissions_data[each.value[0]][each.value[1]])
}


resource "local_file" "permission_sets" {
  for_each = var.create_local_files ? toset([for set in local.permission_sets : "${set[0]}-${set[1]}"]) : toset([])

  content  = module.permission_sets[each.value].policy
  filename = "${path.module}/permissions/${each.value}.json"
}