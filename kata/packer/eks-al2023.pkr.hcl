packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_groups" {
  type = list(string)
}

variable "ami_regions" {
  type = list(string)
}

source "amazon-ebs" "al2023_1_29_eks" {
  ami_name        = "devzero-amazon-eks-node-al2023-x86_64-standard-1.29-{{timestamp}}"
  ami_description = "Devzero Amazon EKS Node AL2023 x86_64 Standard 1.29 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ec2-user"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "amazon-eks-node-al2023-x86_64-standard-1.29-*"
      root-device-type    = "ebs"
    }
    owners = ["602401143452"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 200
    throughput            = 750
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

source "amazon-ebs" "al2023_1_30_eks" {
  ami_name        = "devzero-amazon-eks-node-al2023-x86_64-standard-1.30-{{timestamp}}"
  ami_description = "Devzero Amazon EKS Node AL2023 x86_64 Standard 1.30 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ec2-user"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "amazon-eks-node-al2023-x86_64-standard-1.30-*"
      root-device-type    = "ebs"
    }
    owners = ["602401143452"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 200
    throughput            = 750
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

source "amazon-ebs" "al2023_1_31_eks" {
  ami_name        = "devzero-amazon-eks-node-al2023-x86_64-standard-1.31-{{timestamp}}"
  ami_description = "Devzero Amazon EKS Node AL2023 x86_64 Standard 1.31 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ec2-user"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "amazon-eks-node-al2023-x86_64-standard-1.31-*"
      root-device-type    = "ebs"
    }
    owners = ["602401143452"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 200
    throughput            = 750
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

build {
  name = "build-al2023-with-pvm"
  sources = [
    "source.amazon-ebs.al2023_1_29_eks",
    "source.amazon-ebs.al2023_1_30_eks",
    "source.amazon-ebs.al2023_1_31_eks",
  ]

  provisioner "file" {
    sources = [
      "./kernel.rpm",
      "./kernel-devel.rpm",
      "./kernel-headers.rpm",
    ]
    destination = "/tmp/"
    max_retries = 3
  }

  provisioner "shell" {
    name              = "Upgrade kernel"
    script            = "./upgrade_kernel.sh"
    # Run it as root
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = true
  }

  provisioner "shell" {
    name              = "Reboot after kernel upgrade"
    inline            = ["sudo reboot"]
    pause_before      = "30s"
    timeout           = "30s"
    expect_disconnect = true
  }

  # Wait for instance to be available again
  provisioner "shell" {
    name              = "Wait for instance to come back online"
    inline            = [
      "echo 'Waiting for system to reboot...'",
      "while ! (sudo cloud-init status --wait || systemctl is-system-running | grep -q 'running'); do sleep 10; done"
    ]
    pause_before      = "50s"
  }

  provisioner "file" {
    sources = [
      "./guest-vmlinux",
      "./containerd.toml",
      "./configuration-clh.toml",
      "./configuration-qemu.toml"
    ]
    destination = "/tmp/"
    max_retries = 3
  }

  provisioner "shell" {
    name              = "Install Kata containers"
    script            = "./install-kata.sh"
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = false
  }

  provisioner "shell" {
    name              = "Configure various machine settings"
    script            = "./config.sh"
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = false
  }

  provisioner "shell" {
    name              = "Download docker images using ctr"
    script            = "./pre_cache.sh"
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = false
  }
}
