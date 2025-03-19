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

# Fetch networking details from remote state (dev/network)
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "acs730-week6-rupeshth"
    key    = "dev/network/terraform.tfstate"
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

# Local values for tags
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
  name_prefix  = "${var.prefix}-${var.env}"
}

# Security Group for ALB (Moved before Web SG)
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP from Anywhere"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from anywhere
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

# Bastion Host Security Group (Moved before Web SG)
resource "aws_security_group" "bastion_sg" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Allow SSH from the internet to Bastion"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

# Security Group for Web Servers
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-web-sg"
  description = "Allow HTTP from ALB and SSH from Bastion"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Allow HTTP only from ALB
  }
   # Allow HTTP from Bastion Host
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Allow HTTP from Bastion
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] #
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = local.default_tags
}

# Deploy Web Servers in Private Subnets
resource "aws_instance" "web" {
  count = 2  # Deploying two web instances

  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type[var.env]
  key_name                    = aws_key_pair.dev_key.key_name
  security_groups             = [aws_security_group.web_sg.id]
  subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_ids[count.index]
  associate_public_ip_address = false  # No public IPs, since they are private

  user_data = templatefile("${path.module}/install_httpd.sh.tpl",
    {
      env    = upper(var.env),
      prefix = upper(var.prefix)
    }
  )

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}-web-${count.index}"
  })
}

# Deploy Bastion Host in Public Subnet 2 (Fix: Ensure public subnets exist)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type[var.env]
  key_name                    = aws_key_pair.dev_key.key_name
  security_groups             = [aws_security_group.bastion_sg.id]
  subnet_id                   = length(data.terraform_remote_state.network.outputs.public_subnet_ids) > 1 ? data.terraform_remote_state.network.outputs.public_subnet_ids[1] : data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  associate_public_ip_address = true # Bastion needs a public IP

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}-bastion"
  })
}

# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids # ALB in public subnets

  tags = local.default_tags
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.default_tags
}

# ALB Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Attach Web Servers to Target Group
resource "aws_lb_target_group_attachment" "web_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web[count.index].id
}

# Adding SSH Key
resource "aws_key_pair" "dev_key" {
  key_name   = var.prefix
  public_key = file("${var.prefix}.pem.pub")
}
