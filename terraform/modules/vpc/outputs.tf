output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
    description = "The ID of the VPC created"
}

output "vpc_public_subnet_ids" {
    value = [ "${aws_subnet.public-subnet.*.id}" ]
    description = "The IDs of the public subnet created"
}
