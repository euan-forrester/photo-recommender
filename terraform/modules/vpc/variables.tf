variable "vpc_name" {}
variable "environment" {}
variable "cidr_block" {}
variable "public_subnets" { type = "map" }
variable "private_subnets" { type = "map" }