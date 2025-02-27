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

source "amazon-ebs" "ubuntu_1_29_eks" {
  ami_name        = "devzero-ubuntu-eks-node-24.04-x86_64-standard-1.29-{{timestamp}}"
  ami_description = "Devzero Ubuntu 24.04 EKS Node x86_64 Standard 1.29 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ubuntu"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu-eks/k8s_1.29/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      architecture        = "x86_64"
      state              = "available"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 200
    throughput           = 750
    volume_type          = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

source "amazon-ebs" "ubuntu_1_30_eks" {
  ami_name        = "devzero-ubuntu-eks-node-24.04-x86_64-standard-1.30-{{timestamp}}"
  ami_description = "Devzero Ubuntu 24.04 EKS Node x86_64 Standard 1.30 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ubuntu"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu-eks/k8s_1.30/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      architecture        = "x86_64"
      state              = "available"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 200
    throughput           = 750
    volume_type          = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

source "amazon-ebs" "ubuntu_1_31_eks" {
  ami_name        = "devzero-ubuntu-eks-node-24.04-x86_64-standard-1.31-{{timestamp}}"
  ami_description = "Devzero Ubuntu 24.04 EKS Node x86_64 Standard 1.31 with Kata runtime"
  ami_groups      = var.ami_groups
  instance_type   = "m5.4xlarge"
  region          = "us-west-1"
  ssh_username    = "ubuntu"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu-eks/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      architecture        = "x86_64"
      state              = "available"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 200
    throughput           = 750
    volume_type          = "gp3"
    delete_on_termination = true
  }

  ami_regions = var.ami_regions
}

build {
  name = "build-ubuntu-with-pvm"
  sources = [
    "source.amazon-ebs.ubuntu_1_29_eks",
    "source.amazon-ebs.ubuntu_1_30_eks",
    "source.amazon-ebs.ubuntu_1_31_eks",
  ]

  provisioner "file" {
    sources = [
      "./kernel-headers.deb",
      "./kernel-image.deb",
      "./kernel-libc-dev.deb",
    ]
    destination = "/tmp/"
    max_retries = 3
  }

  provisioner "shell" {
    name              = "Upgrade kernel"
    script            = "./ubuntu_upgrade_kernel.sh"
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
    script            = "./ubuntu_pre_cache.sh"
    execute_command   = "sudo -E {{ .Path }}"
    environment_vars  = ["DEBIAN_FRONTEND=noninteractive"]
    expect_disconnect = false
  }
}
