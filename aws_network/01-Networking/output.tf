output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
}

output "public_subnet_ids" {
  value       = length(aws_subnet.public_subnet) > 0 ? aws_subnet.public_subnet[*].id : []
  description = "List of public subnet IDs (only for dev)"
}

output "igw_id" {
  value = length(aws_internet_gateway.igw) > 0 ? aws_internet_gateway.igw[0].id : null
}

output "public_route_table_id" {
  value = length(aws_route_table.public_rt) > 0 ? aws_route_table.public_rt[0].id : null
}

output "nat_gateway_id" {
  value = length(aws_nat_gateway.nat) > 0 ? aws_nat_gateway.nat[0].id : null
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}