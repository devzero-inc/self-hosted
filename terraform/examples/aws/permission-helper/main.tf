provider "aws" {
  # Replace this with the proper AWS region as terraform does not allow variables in the provider block.
  region = "AWS_REGION"
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

variable "create_aws_user" {
  description = "Whether to create an AWS user with AWS permissions (DEBUG/DEVELOP mode)"
  type = bool
  default = false
}

variable "create_local_files" {
  description = "Whether to create local files with AWS permissions"
  type = bool
  default = false
}

variable "condition_resources" {
  description = "Condition resources to be added to IAM policies"
  default = {}
}

variable "condition_requests" {
  description = "Condition requests to be added to IAM policies"
  default = {}
}

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"
  count  = var.create_aws_user ? 1 : 0

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
    condition_resources = indent(4, yamlencode(var.condition_resources))
    condition_requests = indent(4, yamlencode(var.condition_requests))
  }

  permissions_data = yamldecode(templatefile("${path.module}/permissions.yaml", local.tpl_vars))
  vpc_permissions     = local.permissions_data["vpc"]
  cluster_permissions = local.permissions_data["cluster"]
  efs_permissions     = local.permissions_data["efs"]

  permission_sets = [
    # ["extra", "debug-permissions"], # This is usually only required when debugging permissions. Not for general use.
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

# output "yaml_debug" {
#   value = templatefile("${path.module}/permissions.yaml", local.tpl_vars)
# }