packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
source "amazon-ebs" "ubuntu-eks" {
  ami_name      = "al2-pvm-{{timestamp}}"
  instance_type = "t3.2xlarge"
  region        = "us-west-1"
  # aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.29/amazon-linux-2/recommended/image_id \
  # --region us-west-1 --query "Parameter.Value" --output text
  source_ami = "ami-0242b8629f67f3e22"
  ssh_username = "ec2-user"

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 50
    volume_type = "gp3"
    delete_on_termination = true
  }
}

build {
  name = "upgrade-kernel"
  sources = [
    "source.amazon-ebs.ubuntu-eks"
  ]

  provisioner "file" {
    source = "./kernel.rpm"
    destination = "/tmp/kernel.rpm"
  }

  provisioner "file" {
    source = "./kernel-devel.rpm"
    destination = "/tmp/kernel-devel.rpm"
  }

  provisioner "file" {
    source = "./kernel-headers.rpm"
    destination = "/tmp/kernel-headers.rpm"
  }

  provisioner "shell" {
    name = "Upgrade kernel"
    script = "./upgrade_kernel.sh"
    # Run it as root
    execute_command = "sudo {{ .Path }}"
  }

  provisioner "shell" {
    name              = "Reboot after kernel upgrade"
    inline            = ["sudo reboot"]
    pause_before      = "10s"
    timeout           = "10s"
    expect_disconnect = true
  }

  provisioner "file" {
    source = "./guest-vmlinux"
    destination = "/tmp/vmlinux"
  }

  provisioner "file" {
    source = "./containerd.toml"
    destination = "/tmp/containerd.toml"
  }

  provisioner "file" { 
    source = "./configuration-clh.toml"
    destination = "/tmp/configuration-clh.toml"
  }

  provisioner "file" { 
    source = "./configuration-qemu.toml"
    destination = "/tmp/configuration-qemu.toml"
  }

  provisioner "shell" {
    name = "Install Kata containers"
    script = "./install-kata.sh"
    execute_command = "sudo {{ .Path }}"
    expect_disconnect = false
  }

  provisioner "shell" {
    name              = "Configure various machine settings"
    script            = "./config.sh"
    execute_command   = "sudo {{ .Path }}"
    expect_disconnect = false
  }
}
