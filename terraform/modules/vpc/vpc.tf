resource "aws_vpc" "vpc" {
    cidr_block = "10.10.0.0/16"
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

# Public subnet
resource "aws_subnet" "public-subnet-0-0-1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.10.1.0/24"
    availability_zone = "${var.availability_zone_1}"
    tags {
        Name = "public-subnet0-0-0-${var.vpc_name}-${var.availability_zone_1}-${var.environment}"
    }
}

resource "aws_subnet" "public-subnet-0-0-2" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.10.2.0/24"
    availability_zone = "${var.availability_zone_2}"
    tags {
        Name = "public-subnet0-0-0-${var.vpc_name}-${var.availability_zone_2}-${var.environment}"
    }
}

# Routing table for public subnet
resource "aws_route_table" "public-subnet-0-0-routing-table" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet-gateway.id}"
    }
    tags {
        Name = "public-subnet-0-0-routing-table-${var.vpc_name}-${var.environment}"
    }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "public-subnet-0-0-1-routing-table-association" {
    subnet_id       = "${aws_subnet.public-subnet-0-0-1.id}"
    route_table_id  = "${aws_route_table.public-subnet-0-0-routing-table.id}"
}

resource "aws_route_table_association" "public-subnet-0-0-2-routing-table-association" {
    subnet_id       = "${aws_subnet.public-subnet-0-0-2.id}"
    route_table_id  = "${aws_route_table.public-subnet-0-0-routing-table.id}"
}