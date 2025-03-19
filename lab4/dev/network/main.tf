# Module to deploy networking
module "vpc-dev" {
  source                 = "../../../aws_network/01-Networking"
  vpc_cidr_dev               = var.vpc_cidr_dev
  public_cidr_blocks_dev     = var.public_cidr_blocks_dev
  private_cidr_blocks_dev    = var.private_cidr_blocks_dev
  default_tags           = var.default_tags
  environment = var.env
}