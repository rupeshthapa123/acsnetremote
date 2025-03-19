# Module to deploy basic networking 
module "vpc-prod" {
  source              = "../../../aws_network/01-Networking"
  vpc_cidr_prod        = var.vpc_cidr_prod
  private_cidr_blocks_prod = var.private_cidr_blocks_prod  # Fixed variable name
  default_tags       = var.default_tags
  environment = var.env
}