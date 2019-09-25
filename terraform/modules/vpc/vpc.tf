# Based off of https://dwmkerr.com/dynamic-and-configurable-availability-zones-in-terraform/

resource "aws_vpc" "vpc" {
    cidr_block = "${var.cidr_block}"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags {
        Name = "${var.vpc_name}-${var.environment}"
    }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "internet-gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "internet-gateway-${var.vpc_name}-${var.environment}"
    }
}

# Public subnet - 1 per subnet listed in our variables
resource "aws_subnet" "public-subnet" {
    count = "${length(var.public_subnets)}"

    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "${element(values(var.public_subnets), count.index)}"
    availability_zone = "${element(keys(var.public_subnets), count.index)}"
    tags {
        Name = "public-subnet-${var.vpc_name}-${element(keys(var.public_subnets), count.index)}-${var.environment}"
    }
}

# Private subnet - 1 per subnet listed in our variables
resource "aws_subnet" "private-subnet" {
    count = "${length(var.private_subnets)}"

    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "${element(values(var.private_subnets), count.index)}"
    availability_zone = "${element(keys(var.private_subnets), count.index)}"
    tags {
        Name = "private-subnet-${var.vpc_name}-${element(keys(var.private_subnets), count.index)}-${var.environment}"
    }
}

# Routing table for our public subnets
resource "aws_route_table" "public-subnet-routing-table" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet-gateway.id}"
    }
    tags {
        Name = "public-subnet-routing-table-${var.vpc_name}-${var.environment}"
    }
}

# Associate the routing table to each public subnet
resource "aws_route_table_association" "public-subnet-routing-table-association" {
    count           = "${length(var.public_subnets)}"

    subnet_id       = "${element(aws_subnet.public-subnet.*.id, count.index)}"
    route_table_id  = "${aws_route_table.public-subnet-routing-table.id}"
}
