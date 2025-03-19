# Default tags
variable "default_tags" {
  default = {
    "Owner" = "Rupesh",
    "App"   = "Web"
  }
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}

# Name prefix
variable "prefix" {
  type        = string
  default     = "prod"
  description = "Name prefix"
}

# VPC CIDR range
variable "vpc_cidr_prod" {
  default     = "10.10.0.0/16"
  type        = string
  description = "VPC to host static web site"
}

variable "private_cidr_blocks_prod" {
  type        = list(string)
  description = "Private Subnet CIDRs for Prod"
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

# Variable to signal the current environment 
variable "env" {
  default     = "prod"
  type        = string
  description = "Deployment Environment"
}