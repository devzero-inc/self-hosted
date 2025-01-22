provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = "roblox-env"
}

data "aws_ami" "ubuntu-eks_1_30" {
  name_regex  = "ubuntu-eks/k8s_1.30/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  most_recent = true
  owners      = ["099720109477"]
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
  role_name_prefix  = "${substr(data.aws_eks_cluster.this.name,0 ,(38-length(var.node_role_suffix)))}${var.node_role_suffix}"
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


module "ubuntu_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.31.6"


  name           = "${data.aws_eks_cluster.this.name}-ubuntu-nodes"
  cluster_name = data.aws_eks_cluster.this.name

  instance_types = [var.worker_instance_type]
  key_name       = var.nodes_key_name

  cluster_service_cidr = data.aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr
  subnet_ids = data.aws_eks_cluster.this.vpc_config[0].subnet_ids

  ami_id = data.aws_ami.ubuntu-eks_1_30.image_id

  create_iam_role = false
  iam_role_arn    = module.node_cluster_role.iam_role_arn

  min_size     = 4
  max_size     = 4
  desired_size = 4

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

  bootstrap_extra_args       = "--kubelet-extra-args '--runtime-request-timeout=\"15m\"'"

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


}