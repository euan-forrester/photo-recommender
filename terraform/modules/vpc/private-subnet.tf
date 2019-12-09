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
