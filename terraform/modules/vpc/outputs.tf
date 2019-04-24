output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
    description = "The ID of the VPC created"
}

output "vpc_public_subnet_ids" {
    value = [ "${aws_subnet.public-subnet.*.id}" ]
    description = "The IDs of the public subnet created"
}

output "vpc_cidr_block" {
    value = "${var.cidr_block}"
    description = "The CIDR block covered by the VPC created"
}