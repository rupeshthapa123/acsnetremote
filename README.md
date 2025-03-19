Project Overview

This project automates the provisioning of a multi-environment AWS infrastructure using Terraform. It includes:
# VPCs for dev and prod environments
# VPC Peering between dev and prod
# Bastion Host for secure access to private instances
# Web Servers deployed in private subnets
# Security Groups to control access
# Remote State Storage using S3

My project Folder structure looks like this:
aws_network/
│── 01-Networking/
│   ├── main.tf  # VPC, subnets, NAT, IGW, Route Tables
│   ├── variables.tf
│   ├── outputs.tf
│
│── 02-VPC-Peering/
│   ├── main.tf  # VPC Peering between dev and prod
│   ├── variables.tf
│   ├── outputs.tf

lab4
│── dev/
|   |──network/
|   |   │── main.tf
│   │   ├── config.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   ├── webservers/
│   │   ├── main.tf  # Bastion Host, Web Servers in private subnet
│   │   ├── config.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── install_httpd.sh.tpl  # User data for web servers
│
│── prod/
|   |──network/
|   |   │── main.tf
│   │   ├── config.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   |
|   ├── webservers/
│   │   ├── main.tf  # Web Servers in private subnet (No Bastion)
│   │   ├── config.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf



Prerequisites

Before running Terraform, ensure you have:
1️ AWS CLI configured with credentials (aws configure)
2⃣ Terraform installed (terraform -v)
3⃣ SSH Key for connecting to EC2 instances

Executing the Code:

The code on aws_network - 01 Networking module that supports both environment dev(non-prod) and prod so, we don't have to execute it.
Instead the lab4 dev/network and prod/network both are calling the local module that execute it based on the environment which is dev and prod.

Since, peering comes after both vpc is created it is executed last.

Also, a S3 bucket is used to save remote terraform state which is a bucket has to be created and its name and key
should be included in all file required. 

lab4/dev/network 
config.tf
main.tf

lab4/dev/webservers
config.tf
main.tf

similarly in lab4/prod/network
config.tf
main.tf

also, lab4/prod/webservers
config.tf
main.tf


First, we have to run 
cd lab4/dev/network

terraform init
terraform validate
terraform plan
terraform apply


then cd lab4/dev/webservers

terraform init
terraform validate
terraform plan
terraform apply

also, cd lab4/prod/network
terraform init
terraform validate
terraform plan
terraform apply

then, cd lab4/prod/webservers
terraform init
terraform validate
terraform plan
terraform apply

after this we have to execute peering
cd aws_network/02-VP-Peering

terraform init
terraform validate
terraform plan
terraform apply

For, checking load balancer we can just use the output dns from lab4/dev/webserver 
we can use that url and refresh it to see different IP of VM.

Also, this will execute all the code of the project properly and we can connect to bastion using ssh.

Through bastion we can connect to other private instance vm but we need the private key of those instance inside bastion host.

For that we can copy the private key inside bastion.

ssh -i week7.pem ec2-user@bastionhostpubip

opening the private key
local terminal-
cat ~/environment/lab4/dev/webserver/week7.pem

creating new file and copying the private key within the bastion host
bastion host -
nano ~/.ssh/week7.pem

set correct file permissions
chmod 600 ~/.ssh/week7.pem

ssh into private vm-
ssh -i ~/.ssh/week7.pem ec2-user@private vm ip

This has to be done for prod instance as well in order to connect its VM.



Now, In order to remove all the infrastructure created we can reverse the process and remove everything.
First we have to remove VPC Peering

cd aws_network/02-VPC-Peering

terraform destroy

Then,
cd lab4/prod/webserver 
terraform destroy

cd lab4/prod/network 
terraform destroy

cd lab4/dev/webserver
terraform destroy

cd lab4/dev/network
terraform destroy

This ensures all the infrastructure created previously has been removed.