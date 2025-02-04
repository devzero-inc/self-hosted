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

#source "amazon-ebs" "al2023_1_29_eks" {
#  ami_name        = "devzero-amazon-eks-node-al2023-x86_64-standard-1.29-{{timestamp}}"
#  ami_description = "Devzero Amazon EKS Node AL2023 x86_64 Standard 1.29 with Kata runtime"
#  ami_groups      = var.ami_groups
#  instance_type   = "t3.2xlarge"
#  region          = "us-west-1"
#  ssh_username    = "ec2-user"
#
#  source_ami_filter {
#    filters = {
#      virtualization-type = "hvm"
#      name                = "amazon-eks-node-al2023-x86_64-standard-1.29-*"
#      root-device-type    = "ebs"
#    }
#    owners = ["602401143452"]
#    most_recent = true
#  }
#
#  launch_block_device_mappings {
#    device_name           = "/dev/xvda"
#    volume_size           = 50
#    volume_type           = "gp3"
#    delete_on_termination = true
#  }
#
#  ami_regions = var.ami_regions
#}

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
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

#source "amazon-ebs" "al2023_1_31_eks" {
#  ami_name        = "devzero-amazon-eks-node-al2023-x86_64-standard-1.31-{{timestamp}}"
#  ami_description = "Devzero Amazon EKS Node AL2023 x86_64 Standard 1.31 with Kata runtime"
#  ami_groups      = var.ami_groups
#  instance_type   = "t3.2xlarge"
#  region          = "us-west-1"
#  ssh_username    = "ec2-user"
#
#  source_ami_filter {
#    filters = {
#      virtualization-type = "hvm"
#      name                = "amazon-eks-node-al2023-x86_64-standard-1.31-*"
#      root-device-type    = "ebs"
#    }
#    owners = ["602401143452"]
#    most_recent = true
#  }
#
#  launch_block_device_mappings {
#    device_name           = "/dev/xvda"
#    volume_size           = 50
#    volume_type           = "gp3"
#    delete_on_termination = true
#  }
#
#  ami_regions = var.ami_regions
#}

build {
  name = "upgrade-kernel"
  sources = [
    #"source.amazon-ebs.al2023_1_29_eks",
    "source.amazon-ebs.al2023_1_30_eks",
    #"source.amazon-ebs.al2023_1_31_eks",
  ]

  provisioner "file" {
    source      = "./kernel.rpm"
    destination = "/tmp/kernel.rpm"
  }

  provisioner "file" {
    source      = "./kernel-devel.rpm"
    destination = "/tmp/kernel-devel.rpm"
  }

  provisioner "file" {
    source      = "./kernel-headers.rpm"
    destination = "/tmp/kernel-headers.rpm"
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

  provisioner "file" {
    source      = "./guest-vmlinux"
    destination = "/tmp/vmlinux"
  }

  provisioner "file" {
    source      = "./containerd.toml"
    destination = "/tmp/containerd.toml"
  }

  provisioner "file" {
    source      = "./configuration-clh.toml"
    destination = "/tmp/configuration-clh.toml"
  }

  provisioner "file" {
    source      = "./configuration-qemu.toml"
    destination = "/tmp/configuration-qemu.toml"
  }

  provisioner "shell" {
    name              = "Install Kata containers"
    script            = "./install-kata.sh"
    execute_command   = "sudo {{ .Path }}"
    pause_before      = "50s"
    expect_disconnect = false
  }

  provisioner "shell" {
    name              = "Configure various machine settings"
    script            = "./config.sh"
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = false
  }
}
