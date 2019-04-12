module "elastic-container-service" {
    source = "../elastic-container-service"

    cluster_name = "puller-flickr-${var.environment}"
    region = "${var.region}"
    environment = "${var.environment}"
    availability_zone = "${var.availability_zone}"

    local_machine_cidr = "${var.local_machine_cidr}"
    local_machine_public_key = "${var.local_machine_public_key}"

    instance_type = "${var.ecs_instance_type}"

    cluster_desired_size = "${var.ecs_cluster_desired_size}"
    cluster_min_size = "${var.ecs_cluster_min_size}"
    cluster_max_size = "${var.ecs_cluster_max_size}"

    instances_desired_count = "${var.ecs_instances_desired_count}"
    instances_memory = "${var.ecs_instances_memory}"
    instances_cpu = "${var.ecs_instances_cpu}"
    instances_log_retention_days = "${var.ecs_instances_log_retention_days}"

    instances_extra_policy_arn = "${aws_iam_policy.ecs-instance-puller-flickr-extra-policy.arn}"
}

data "aws_caller_identity" "puller-flickr" {
  
}

resource "aws_iam_policy" "ecs-instance-puller-flickr-extra-policy" {
  name        = "puller-flickr-extra-policy"
  description = "Allows puller-flickr to read parameters and write to Kafka"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.puller-flickr.account_id}:parameter/${var.environment}/puller-flickr/*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "${aws_kms_key.parameter_secrets.arn}"
    },
    {
      "Action": [
        "sqs:SendMessageBatch",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${var.output_queue_arn}"
    }
  ]
}
EOF
}
