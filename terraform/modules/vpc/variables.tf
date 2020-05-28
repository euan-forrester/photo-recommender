variable "vpc_name" {
}

variable "environment" {
}

variable "cidr_block" {
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
}

