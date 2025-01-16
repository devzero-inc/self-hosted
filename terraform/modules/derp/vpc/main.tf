locals {
  # Use existing or created VPC ID
  vpc_id = aws_vpc.derp_vpc.id
  # Use existing or created subnet ID
  subnet_id = aws_subnet.derp_subnet.id
  # Use existing or created security group ID
  security_group_id = aws_security_group.derp_sg.id 
  aws_region = "us-west-2"

}

# Configure AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create VPC if no existing VPC ID provided
resource "aws_vpc" "derp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create Internet Gateway if creating VPC
resource "aws_internet_gateway" "derp_igw" {
  vpc_id = local.vpc_id
}

# Create Public Subnet if no existing subnet ID provided
resource "aws_subnet" "derp_subnet" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${local.aws_region}a"
}

# Create Route Table if creating VPC
resource "aws_route_table" "derp_rt" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.derp_igw.id
  }
}

# Associate Route Table with Subnet if creating both
resource "aws_route_table_association" "derp_rta" {
  subnet_id      = local.subnet_id
  route_table_id = aws_route_table.derp_rt.id
}

# Create Security Group if no existing security group ID provided
resource "aws_security_group" "derp_sg" {
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_instance" "derp_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  key_name      = "kevinkeyeng"
  associate_public_ip_address = true

  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [local.security_group_id]
  metadata_options {
    http_tokens = "optional"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
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