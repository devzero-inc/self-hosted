data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

module "node_cluster_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.51.0"

  trusted_role_services = [
    "ec2.amazonaws.com",
  ]
  trusted_role_actions = [
    "sts:AssumeRole",
  ]

  create_role       = true
  role_name_prefix  = "${substr(data.aws_eks_cluster.this.name, 0, (38 - length(var.node_role_suffix)))}${var.node_role_suffix}"
  role_description  = "EKS managed node group IAM role"
  role_requires_mfa = false

  force_detach_policies = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}


module "kata_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.31.6"

  name = "${substr(data.aws_eks_cluster.this.name, 0, (36 - length(var.node_group_suffix)))}${var.node_group_suffix}"

  cluster_name = data.aws_eks_cluster.this.name

  instance_types = [var.instance_type]
  key_name       = var.nodes_key_name

  cluster_service_cidr = data.aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr
  subnet_ids           = data.aws_eks_cluster.this.vpc_config[0].subnet_ids

  ami_id = var.ami_id

  create_iam_role = false
  iam_role_arn    = module.node_cluster_role.iam_role_arn

  min_size     = var.min_size
  max_size     = var.max_size
  desired_size = var.desired_size

  enable_bootstrap_user_data = true

  post_bootstrap_user_data = <<-EOT
    #!/bin/bash
    set -o xtrace
    # Backup the original config.toml
    cp /etc/containerd/config.toml /etc/containerd/config.toml.bak

    echo '' >> /etc/containerd/config.toml
    echo '[plugins."io.containerd.grpc.v1.cri".registry.configs."docker-registry.devzero.svc.cluster.local:5000".tls]'  >> /etc/containerd/config.toml
    echo '  insecure_skip_verify = true'  >> /etc/containerd/config.toml

    # Restart containerd to apply the changes
    systemctl restart containerd
    EOT

  block_device_mappings = {
    sda = {
      device_name = "/dev/sda1"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 500
        volume_type           = "gp3"
      }
    }
  }

  update_config = {
    max_unavailable_percentage = 33
  }

  labels = {
    "kata-runtime" = "running"
  }

}
