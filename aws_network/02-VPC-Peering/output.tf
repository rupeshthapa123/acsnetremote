output "vpc_peering_id" {
  value = aws_vpc_peering_connection.dev_prod_peering.id
}