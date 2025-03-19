# Output Dev VPC ID
output "vpc_id" {
  description = "ID of the created Dev VPC"
  value       = module.vpc-dev.vpc_id
}

# Output Dev VPC CIDR
output "vpc_cidr" {
  description = "CIDR block of Dev VPC"
  value       = module.vpc-dev.vpc_cidr
}

# Output Public Subnet IDs
output "public_subnet_ids" {
  description = "List of Public Subnet IDs in Dev"
  value       = module.vpc-dev.public_subnet_ids
}

# Output Private Subnet IDs
output "private_subnet_ids" {
  description = "List of Private Subnet IDs in Dev"
  value       = module.vpc-dev.private_subnet_ids
}

# Output Internet Gateway ID
output "igw_id" {
  description = "Internet Gateway ID in Dev"
  value       = module.vpc-dev.igw_id
}

# Output NAT Gateway ID (if exists)
output "nat_gateway_id" {
  description = "NAT Gateway ID (only in Dev)"
  value = module.vpc-dev.nat_gateway_id != null ? module.vpc-dev.nat_gateway_id : null
}


# Output Route Table IDs
output "public_route_table_id" {
  description = "Public Route Table ID in Dev"
  value       = module.vpc-dev.public_route_table_id
}

output "private_route_table_id" {
  description = "Private Route Table ID in Dev"
  value       = module.vpc-dev.private_route_table_id
}