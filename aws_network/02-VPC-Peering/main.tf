terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Fetch remote state from dev and prod
data "terraform_remote_state" "dev" {
  backend = "s3"  # state in S3
  config = {
    bucket = "acs730-week6-rupeshth"
    key    = "dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}
data "terraform_remote_state" "prod" {
  backend = "s3"  # state in S3
  config = {
    bucket = "acs730-week6-rupeshth"
    key    = "prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}


# VPC Peering Connection
resource "aws_vpc_peering_connection" "dev_prod_peering" {
  peer_vpc_id = data.terraform_remote_state.prod.outputs.vpc_id
  vpc_id      = data.terraform_remote_state.dev.outputs.vpc_id
  auto_accept = true

  tags = {
    Name = "dev-prod-peering"
  }
}

# Route Table Updates for Dev Public Subnets
resource "aws_route" "dev_to_prod" {
  count                     = length(data.terraform_remote_state.dev.outputs.public_subnet_ids) > 0 ? 1 : 0
  route_table_id            = data.terraform_remote_state.dev.outputs.public_route_table_id
  destination_cidr_block    = data.terraform_remote_state.prod.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.dev_prod_peering.id

  lifecycle {
    ignore_changes = [destination_cidr_block, vpc_peering_connection_id]
  }
}

resource "aws_route" "prod_to_dev" {
  count                     = length(data.terraform_remote_state.prod.outputs.private_subnet_ids) > 0 ? 1 : 0
  route_table_id            = data.terraform_remote_state.prod.outputs.private_route_table_id
  destination_cidr_block    = data.terraform_remote_state.dev.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.dev_prod_peering.id

  lifecycle {
    ignore_changes = [destination_cidr_block, vpc_peering_connection_id]
  }
}