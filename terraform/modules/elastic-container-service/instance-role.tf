resource "aws_iam_role" "ecs-instance-role" {
    name                = "ecs-instance-role-${var.cluster_name}"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

data "aws_iam_policy_document" "ecs-instance-policy" {
    statement {
        actions = [
            "sts:AssumeRole"
        ]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
    role       = "${aws_iam_role.ecs-instance-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# An extra policy specifically for the container that we're running: the extra stuff that this specific container needs to be able to do
resource "aws_iam_role_policy_attachment" "attach-extra-policy" {
    role       = "${aws_iam_role.ecs-instance-role.name}"
    policy_arn = "${var.instances_extra_policy_arn}"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
    name = "ecs-instance-profile-${var.cluster_name}"
    path = "/"
    role = "${aws_iam_role.ecs-instance-role.id}"
    provisioner "local-exec" {
        command = "sleep 10"
    }
}