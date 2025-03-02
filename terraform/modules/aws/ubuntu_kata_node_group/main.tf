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


module "ubuntu_kata_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.31.6"

  name = "${substr(data.aws_eks_cluster.this.name, 0, (36 - length(var.node_group_suffix)))}${var.node_group_suffix}"

  cluster_name = data.aws_eks_cluster.this.name
  cluster_endpoint = data.aws_eks_cluster.this.endpoint
  cluster_auth_base64 = data.aws_eks_cluster.this.certificate_authority[0].data
  cluster_service_cidr = data.aws_eks_cluster.this.kubernetes_network_config[0].service_ipv4_cidr


  instance_types = [var.instance_type]
  key_name       = var.nodes_key_name

  subnet_ids           = coalescelist(var.subnet_ids, tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids))

  ami_id = var.ami_id
  ami_type = "CUSTOM"

  create_iam_role = false
  iam_role_arn    = module.node_cluster_role.iam_role_arn

  min_size     = var.min_size
  max_size     = var.max_size
  desired_size = var.desired_size

  enable_bootstrap_user_data = true

  post_bootstrap_user_data = <<-EOT
  #!/bin/bash
  set -ex

  while ! systemctl is-active --quiet containerd; do
      sleep 2
  done

  sudo mkdir -p /etc/containerd

  if [ -f /etc/containerd/config.toml ]; then
      sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup
  fi

  cat <<EOF | sudo tee -a /etc/containerd/config.toml
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  privileged_without_host_devices = true

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata-qemu]
  runtime_type = "io.containerd.kata-qemu.v2"
  privileged_without_host_devices = true
  EOF

  sudo systemctl restart containerd
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
    "node-role.kubernetes.io/devpod-node" = 1
    "node-role.kubernetes.io/vcluster-node" = 1
    "node-role.kubernetes.io/kata-devpod-node" = 1
  }

}