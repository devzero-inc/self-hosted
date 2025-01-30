# Local variables for conditional logic
locals {
  create_security_group = var.security_group_id == ""
  create_eip            = var.public_derp && var.existing_eip_id == ""

  # Use existing or created EIP ID
  eip_id = local.create_eip ? aws_eip.derp_eip[0].id : var.existing_eip_id
  # Use existing or created security group ID
  security_group_id = local.create_security_group ? aws_security_group.derp_sg[0].id : var.security_group_id
}

# Create Elastic IP
resource "aws_eip" "derp_eip" {
  count  = local.create_eip ? 1 : 0
  domain = "vpc"

  tags = var.tags
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "derp_eip_assoc" {
  count         = var.public_derp ? 1 : 0
  instance_id   = aws_instance.derp_server.id
  allocation_id = local.eip_id
}

# Create Security Group if no existing security group ID provided
resource "aws_security_group" "derp_sg" {
  count = local.create_security_group ? 1 : 0

  name        = "${var.security_group_prefix}-derp-security-group"
  description = "Security group for DERP server"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = var.tags
}

# Create EC2 Instance
resource "aws_instance" "derp_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [local.security_group_id]

  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/derp-init.tpl", {
    hostname = var.hostname
    public_derp = var.public_derp
  })

  tags = var.tags
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for existing EIP if provided
data "aws_eip" "existing" {
  count = var.existing_eip_id != "" ? 1 : 0
  id    = var.existing_eip_id
}
