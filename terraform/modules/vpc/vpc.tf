# Based off of https://dwmkerr.com/dynamic-and-configurable-availability-zones-in-terraform/

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "internet-gateway-${var.vpc_name}-${var.environment}"
  }
}

