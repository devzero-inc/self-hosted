# Local variables for conditional logic
locals {
  create_vpc            = var.existing_vpc_id == ""
  create_subnet         = var.existing_subnet_id == ""
  create_security_group = var.existing_security_group_id == ""
  create_eip            = var.public_derp && var.existing_eip_id == ""


  # Use existing or created EIP ID
  eip_id = local.create_eip ? aws_eip.derp_eip[0].id : var.existing_eip_id
  # Use existing or created VPC ID
  vpc_id = local.create_vpc ? aws_vpc.derp_vpc[0].id : var.existing_vpc_id
  # Use existing or created subnet ID
  subnet_id = local.create_subnet ? aws_subnet.derp_subnet[0].id : var.existing_subnet_id
  # Use existing or created security group ID
  security_group_id = local.create_security_group ? aws_security_group.derp_sg[0].id : var.existing_security_group_id

  # Common tags
  common_tags = {
    Component = "devzero-derp"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create Elastic IP
resource "aws_eip" "derp_eip" {
  count  = local.create_eip ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "devzero-derp-eip"
  })
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "derp_eip_assoc" {
  count         = var.public_derp ? 1 : 0
  instance_id   = aws_instance.derp_server.id
  allocation_id = local.eip_id
}


# Create VPC if no existing VPC ID provided
resource "aws_vpc" "derp_vpc" {
  count = local.create_vpc ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "devzero-derp-vpc"
  })
}

# Create Internet Gateway if creating VPC
resource "aws_internet_gateway" "derp_igw" {
  count = local.create_vpc ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(local.common_tags, {
    Name = "devzero-derp-igw"
  })
}

# Create Public Subnet if no existing subnet ID provided
resource "aws_subnet" "derp_subnet" {
  count = local.create_subnet ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "devzero-derp-subnet"
  })
}

# Create Route Table if creating VPC
resource "aws_route_table" "derp_rt" {
  count = local.create_vpc ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.derp_igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "devzero-derp-rt"
  })
}

# Associate Route Table with Subnet if creating both
resource "aws_route_table_association" "derp_rta" {
  count = local.create_subnet && local.create_vpc ? 1 : 0

  subnet_id      = local.subnet_id
  route_table_id = aws_route_table.derp_rt[0].id
}

# Create Security Group if no existing security group ID provided
resource "aws_security_group" "derp_sg" {
  count = local.create_security_group ? 1 : 0

  name        = "devzero-derp-security-group"
  description = "Security group for DERP server"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "devzero-derp-sg"
  })
}

# Create EC2 Instance
resource "aws_instance" "derp_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  subnet_id                   = local.subnet_id
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

  tags = merge(local.common_tags, {
    Name = "devzero-derp-server"
  })
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

output "derp_server_elastic_ip" {
  value = var.public_derp ? local.create_eip ? aws_eip.derp_eip[0].public_ip : data.aws_eip.existing[0].public_ip : null
}

output "derp_server_elastic_ip_id" {
  value = var.public_derp ? local.eip_id : null
}

output "derp_server_private_ip" {
  value = aws_instance.derp_server.private_ip
}

output "derp_server_public_ip" {
  value = aws_instance.derp_server.public_ip
}

output "vpc_id" {
  value = local.vpc_id
}

output "subnet_id" {
  value = local.subnet_id
}

output "security_group_id" {
  value = local.security_group_id
}