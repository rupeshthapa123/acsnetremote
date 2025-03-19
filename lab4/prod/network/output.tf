output "private_subnet_ids" {
  value = module.vpc-prod.private_subnet_ids
}

output "vpc_id" {
  value = module.vpc-prod.vpc_id
}

output "vpc_cidr" {
  value = module.vpc-prod.vpc_cidr
}

output "private_route_table_id" {
  value = module.vpc-prod.private_route_table_id
}