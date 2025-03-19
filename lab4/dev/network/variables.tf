# Default tags
variable "default_tags" {
  type        = map(string)
  default     = {
    "Owner" = "Rupesh"
    "App"   = "Web"
  }
  description = "Default tags to be applied to all AWS resources"
}

# Name prefix
variable "prefix" {
  type        = string
  default     = "dev"
  description = "Name prefix"
}

# Public Subnets CIDR blocks
variable "public_cidr_blocks_dev" {
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
  description = "Public Subnet CIDRs"
}

# Private Subnets CIDR blocks for Dev
variable "private_cidr_blocks_dev" {
  type        = list(string)
  default     = ["10.1.3.0/24", "10.1.4.0/24"]
  description = "Private Subnet CIDRs for Dev environment"
}

# VPC CIDR range
variable "vpc_cidr_dev" {
  type        = string
  default     = "10.1.0.0/16"
  description = "VPC CIDR block"
}

# Deployment Environment
variable "env" {
  type        = string
  default     = "dev"
  description = "Deployment Environment (e.g., dev, prod)"
}