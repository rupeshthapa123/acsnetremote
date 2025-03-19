output "private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.linuxvm[*].private_ip
}  