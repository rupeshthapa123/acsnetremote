# Output Web Server Private IPs
output "web_private_ips" {
  value = aws_instance.web[*].private_ip
  description = "Private IPs of Web Servers"
}

# Output ALB DNS Name
output "web_alb_dns" {
  value = aws_lb.web_alb.dns_name
  description = "Public DNS Name of the Load Balancer"
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}
