# ECS Instance Security group

resource "aws_security_group" "ecs" {
    name = "security-group-ecs-${var.cluster_name}-${var.environment}"
    description = "Allow public access from our local network to ECS"
    vpc_id = "${var.vpc_id}"

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
        Name = "security-group-ecs-${var.cluster_name}-${var.environment}"
    }
}