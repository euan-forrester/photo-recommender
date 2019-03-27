resource "aws_vpc" "ecs" {
    cidr_block = "200.0.0.0/16"
    tags {
        Name = "ecs-vpc-${var.environment}"
    }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "ecs" {
    vpc_id = "${aws_vpc.ecs.id}"
    tags {
        Name = "ecs-internet-gateway-${var.environment}"
    }
}

# Public subnet
resource "aws_subnet" "ecs-public-subnet-0-0" {
    vpc_id = "${aws_vpc.ecs.id}"
    cidr_block = "200.0.0.0/24"
    availability_zone = "${var.availability_zone}"
    tags {
        Name = "ecs-public-subnet0-0-0-${var.environment}"
    }
}

# Routing table for public subnet
resource "aws_route_table" "ecs-public-subnet-0-0-routing-table" {
    vpc_id = "${aws_vpc.ecs.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.ecs.id}"
    }
    tags {
        Name = "public-subnet-0-0-routing-table-${var.environment}"
    }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "ecs-public-subnet-0-0-routing-table-association" {
    subnet_id = "${aws_subnet.ecs-public-subnet-0-0.id}"
    route_table_id = "${aws_route_table.ecs-public-subnet-0-0-routing-table.id}"
}

# ECS Instance Security group

resource "aws_security_group" "ecs" {
    name = "security-group-ecs-${var.environment}"
    description = "Test public access security group"
    vpc_id = "${aws_vpc.ecs.id}"

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "${var.local_machine_cidr}"
        ]
    }

    egress {
        # allow all traffic to private SN
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

    tags { 
        Name = "security-group-ecs-${var.environment}"
    }
}