variable "environment" {
  type        = string
  description = "Environment name (dev or prod)"
}

variable "vpc_cidr_dev" {
  type    = string
  default = "10.1.0.0/16"
}

variable "vpc_cidr_prod" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_cidr_blocks_dev" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_cidr_blocks_dev" {
  type    = list(string)
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "private_cidr_blocks_prod" {
  type    = list(string)
  default = ["10.10.3.0/24", "10.10.4.0/24"]
}

variable "default_tags" {
  type    = map(string)
  default = { "Owner" = "Rupesh", "App" = "Web" }
}