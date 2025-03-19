terraform {
  backend "s3" {
    bucket = "acs730-week6-rupeshth"
    key    = "dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}