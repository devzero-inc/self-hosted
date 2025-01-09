data "aws_iam_policy_document" "eks-cluster-policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "eks-cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks-cluster-policy.json
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-cluster.name
}

data "aws_ami" "k8s_ubuntu_ami_1_29" {
  name_regex  = "ubuntu-eks/k8s_1.30/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  most_recent = true
  owners      = ["099720109477"]
}

resource "aws_launch_template" "ubuntu" {
  name_prefix   = "${var.cluster_name}-ubuntu"
  image_id      = data.aws_ami.k8s_ubuntu_ami_1_29.id

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -e

    # Cluster-specific values
    B64_CLUSTER_CA="${aws_eks_cluster.this.certificate_authority[0].data}"
    API_SERVER_URL="${data.aws_eks_cluster.cluster.endpoint}"

    # Bootstrap the node
    /etc/eks/bootstrap.sh "${aws_eks_cluster.this.name}" \
      --b64-cluster-ca $B64_CLUSTER_CA \
      --apiserver-endpoint $API_SERVER_URL
  EOT
  )

  vpc_security_group_ids = var.security_group_ids

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.disk_size
    }
  }

  tags = merge(
    {
      Name = "${var.cluster_name}-launch-template"
    },
    var.common_tags
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ Name = "${var.cluster_name}-node" }, var.common_tags)
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster.arn
  version  = "1.30"

  enabled_cluster_log_types = []

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    # See access entries below - this is a one time operation from the EKS API.
    # Instead, we are hardcoding this to false and if users wish to achieve this
    # same functionality, we will do that through an access entry which can be
    # enabled or disabled at any time of their choosing using the variable
    # var.enable_cluster_creator_admin_permissions
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    security_group_ids      = var.security_group_ids
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(
    {
      Terraform = "true"
      Name      = var.cluster_name
    }, var.common_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEBSCSIDriverPolicy,
  ]
}

data "aws_iam_policy_document" "eks-node-policy" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "eks-node" {
  name = "${var.cluster_name}-node-iam-role"

  assume_role_policy = data.aws_iam_policy_document.eks-node-policy.json
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${aws_eks_cluster.this.name}-ng"
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.worker_instance_type]
  ami_type        = "CUSTOM"

  scaling_config {
    desired_size = var.desired_node_size
    max_size     = var.max_node_size
    min_size     = var.min_node_size
  }

  launch_template {
    id      = aws_launch_template.ubuntu.id
    version = aws_launch_template.ubuntu.latest_version
  }

  tags = merge(
    {
      Terraform = "true"
      Name      = "${aws_eks_cluster.this.name}-ng"
    }, var.common_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks-node-AmazonEBSCSIDriverPolicy,
  ]
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.cluster.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.cluster.url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

data "aws_eks_cluster" "cluster" {
  name = concat(aws_eks_cluster.this.*.id, [""])[0]
}

data "aws_eks_cluster_auth" "cluster" {
  name = concat(aws_eks_cluster.this.*.id, [""])[0]
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates.0.sha1_fingerprint]
  url             = flatten(concat(aws_eks_cluster.this[*].identity[*].oidc.0.issuer, [""]))[0]

  tags = merge(
    {
      Terraform           = "true"
      KubespotEnvironment = var.environment
    }, var.common_tags
  )
}

data "tls_certificate" "cluster" {
  url = flatten(concat(aws_eks_cluster.this[*].identity[*].oidc.0.issuer, [""]))[0]
}


################################################################################
# Access Entry
################################################################################
# Copied from AWS EKS module
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}


locals {
  # This replaces the one time logic from the EKS API with something that can be
  # better controlled by users through Terraform
  bootstrap_cluster_creator_admin_permissions = {
    cluster_creator = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Merge the bootstrap behavior with the entries that users provide
  merged_access_entries = merge(
    { for k, v in local.bootstrap_cluster_creator_admin_permissions : k => v if var.enable_cluster_creator_admin_permissions },
    var.access_entries,
  )

  # Flatten out entries and policy associations so users can specify the policy
  # associations within a single entry
  flattened_access_entries = flatten([
    for entry_key, entry_val in local.merged_access_entries : [
      for pol_key, pol_val in lookup(entry_val, "policy_associations", {}) :
      merge(
        {
          principal_arn = entry_val.principal_arn
          entry_key     = entry_key
          pol_key       = pol_key
        },
        { for k, v in {
          association_policy_arn              = pol_val.policy_arn
          association_access_scope_type       = pol_val.access_scope.type
          association_access_scope_namespaces = lookup(pol_val.access_scope, "namespaces", [])
        } : k => v if !contains(["EC2_LINUX", "EC2_WINDOWS", "FARGATE_LINUX"], lookup(entry_val, "type", "STANDARD")) },
      )
    ]
  ])
}

resource "aws_eks_access_entry" "this" {
  for_each = { for k, v in local.merged_access_entries : k => v }

  cluster_name      = aws_eks_cluster.this.name
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  user_name         = try(each.value.user_name, null)
}

resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in local.flattened_access_entries : "${v.entry_key}_${v.pol_key}" => v }

  access_scope {
    namespaces = try(each.value.association_access_scope_namespaces, [])
    type       = each.value.association_access_scope_type
  }

  cluster_name = aws_eks_cluster.this.name

  policy_arn    = each.value.association_policy_arn
  principal_arn = each.value.principal_arn

  depends_on = [
    aws_eks_access_entry.this,
  ]
}
