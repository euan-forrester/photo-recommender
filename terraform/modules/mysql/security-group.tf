resource "aws_security_group" "rds" {
    name = "security-group-rds-${var.database_name}-${var.environment}"
    description = "Allow access from our local machine and VPC to RDS"
    vpc_id = "${var.vpc_id}"

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [
            "${var.local_machine_cidr}",
            "${var.vpc_cidr}"
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
        Name = "security-group-rds-${var.database_name}-${var.environment}"
    }
}