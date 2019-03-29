data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "local_machine" {
    key_name   = "local_machine"
    public_key = "${var.local_machine_public_key}"
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
    name                        = "ecs-launch-configuration-${var.environment}"
    image_id                    = "${data.aws_ami.ubuntu.id}"
    instance_type               = "${var.instance_type}"
    iam_instance_profile        = "${aws_iam_instance_profile.ecs-instance-profile.id}"

    root_block_device {
        volume_type = "standard"
        volume_size = 100
        delete_on_termination = true
    }

    lifecycle {
        create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.ecs.id}"]
    associate_public_ip_address = "true"
    key_name                    = "${aws_key_pair.local_machine.key_name}"
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
                                  EOF
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
    name                        = "ecs-autoscaling-group-${var.environment}"
    max_size                    = "${var.cluster_max_size}"
    min_size                    = "${var.cluster_min_size}"
    desired_capacity            = "${var.cluster_desired_size}"
    vpc_zone_identifier         = ["${aws_subnet.ecs-public-subnet-0-0.id}"]
    launch_configuration        = "${aws_launch_configuration.ecs-launch-configuration.name}"
    health_check_type           = "ELB"
}

resource "aws_ecs_cluster" "ecs-cluster" {
    name = "${var.cluster_name}"
}