output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
    description = "The ID of the VPC created"
}

output "vpc_public_subnet_ids" {
    value = [ "${aws_subnet.public-subnet.*.id}" ]
    description = "The IDs of the public subnets created"
}

output "vpc_public_subnet_arns" {
    value = [ "${aws_subnet.public-subnet.*.arn}" ]
    description = "The ARNs of the public subnets created"
}

output "vpc_private_subnet_ids" {
    value = [ "${aws_subnet.private-subnet.*.id}" ]
    description = "The IDs of the private subnets created"
}

output "vpc_private_subnet_arns" {
    value = [ "${aws_subnet.private-subnet.*.arn}" ]
    description = "The ARNs of the private subnets created"
}

output "vpc_cidr_block" {
    value = "${var.cidr_block}"
    description = "The CIDR block covered by the VPC created"
}