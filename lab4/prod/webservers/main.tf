terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Fetch the remote state from the S3 bucket
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "acs730-week6-rupeshth"  # S3 Bucket where the state is stored
    key    = "prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Fetch the latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Define local variables
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"
}

# Create two EC2 instances in the private subnets
resource "aws_instance" "linuxvm" {
  count         = 2
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh_key.key_name
  subnet_id     = data.terraform_remote_state.network.outputs.private_subnet_ids[count.index]
  security_groups = [aws_security_group.webserver_sg.id]

  root_block_device {
    encrypted = true
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}-linuxvm-${count.index + 1}"
  })
}

# Adding SSH Key
resource "aws_key_pair" "ssh_key" {
  key_name   = var.prefix
  public_key = file("${var.prefix}.pem.pub")
}


# Security Group
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-ssh"
  description = "Allow only SSH traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Allow SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}-sg"
  })
}