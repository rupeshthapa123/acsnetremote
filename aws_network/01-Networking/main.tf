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

# Data Source for Availability Zones
data "aws_availability_zones" "available" {}

# Environment-based local variables
locals {
  is_prod       = var.environment == "prod"
  vpc_name      = local.is_prod ? "prod-vpc" : "dev-vpc"
  vpc_cidr      = local.is_prod ? var.vpc_cidr_prod : var.vpc_cidr_dev
  public_cidrs  = local.is_prod ? [] : var.public_cidr_blocks_dev
  private_cidrs = local.is_prod ? var.private_cidr_blocks_prod : var.private_cidr_blocks_dev
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = merge(var.default_tags, { Name = local.vpc_name })
}

# Public Subnets (Only for Dev)
resource "aws_subnet" "public_subnet" {
  count             = length(local.public_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.default_tags, { Name = "${local.vpc_name}-public-subnet-${count.index + 1}" })
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(var.default_tags, { Name = "${local.vpc_name}-private-subnet-${count.index + 1}" })
}

# Internet Gateway (Only for Dev)
resource "aws_internet_gateway" "igw" {
  count  = local.is_prod ? 0 : 1
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, { "Name" = "${local.vpc_name}-igw" })
}

# Elastic IP & NAT Gateway (Only for Dev)
resource "aws_eip" "nat_eip" {
  count  = local.is_prod ? 0 : 1
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = local.is_prod ? 0 : 1
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(var.default_tags, { Name = "${local.vpc_name}-nat-gw" })
}

# Public Route Table (Only for Dev)
resource "aws_route_table" "public_rt" {
  count  = local.is_prod ? 0 : 1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = merge(var.default_tags, { Name = "${local.vpc_name}-public-rt" })
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags, { Name = "${local.vpc_name}-private-rt" })
}

# Private NAT Route (Only for Dev)
resource "aws_route" "private_nat_route" {
  count                  = length(aws_nat_gateway.nat) > 0 ? 1 : 0
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = length(aws_nat_gateway.nat) > 0 ? aws_nat_gateway.nat[0].id : null
}

# Route Table Associations
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_route_table.public_rt) > 0 ? length(aws_subnet.public_subnet) : 0
  route_table_id = aws_route_table.public_rt[0].id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnet)
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}