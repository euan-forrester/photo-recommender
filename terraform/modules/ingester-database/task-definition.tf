module "task_definition" {
    source = "../task-definition"

    name                        = "ingester-database-${var.environment}"
    environment                 = "${var.environment}"
    region                      = "${var.region}"
    container_repository_url    = "${module.container_repository.repository_url}"
    cluster_id                  = "${var.ecs_cluster_id}"
    instances_memory            = "${var.ecs_instances_memory}"
    instances_cpu               = "${var.ecs_instances_cpu}"
    instances_log_configuration = "${var.ecs_instances_log_configuration}"
    instances_desired_count     = "${var.ecs_instances_desired_count}"
    instances_role_name         = "${var.ecs_instances_role_name}"
    instances_extra_policy_arn  = "${aws_iam_policy.ecs-instance-ingester-database-extra-policy.arn}"
    port_mappings               = ""
    has_load_balancer           = false
    load_balancer_container_port = -1
    load_balancer_target_group_arn = ""
}

data "aws_caller_identity" "ingester_database" {
  
}

resource "aws_iam_policy" "ecs-instance-ingester-database-extra-policy" {
  name        = "ingester-database-extra-policy-${var.environment}"
  description = "Allows ingester-database to read parameters, read from the ingestion queue, and talk to the favorites database"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.ingester_database.account_id}:parameter/${var.environment}/ingester-database/*"
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
        "sqs:ReceiveMessage",
        "sqs:DeleteMessageBatch",
        "sqs:DeleteMessage"
      ],
      "Effect": "Allow",
      "Resource": "${module.input_sqs_queue.queue_arn}"
    },
    {
      "Action": [
        "sqs:SendMessageBatch",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${module.output_sqs_queue.queue_arn}"
    }
  ]
}
EOF
}