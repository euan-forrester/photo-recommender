module "task_definition" {
    source = "../task-definition"

    name                        = "scheduler-${var.environment}"
    environment                 = "${var.environment}"
    region                      = "${var.region}"
    container_repository_url    = "${module.container_repository.repository_url}"
    cluster_id                  = "${var.ecs_cluster_id}"
    instances_memory            = "${var.ecs_instances_memory}"
    instances_cpu               = "${var.ecs_instances_cpu}"
    instances_log_configuration = "${var.ecs_instances_log_configuration}"
    instances_desired_count     = "${var.ecs_instances_desired_count}"
    instances_role_name         = "${var.ecs_instances_role_name}"
    instances_extra_policy_arn  = "${aws_iam_policy.ecs-instance-scheduler-extra-policy.arn}"
    port_mappings               = ""
    has_load_balancer           = false
    load_balancer_container_port = -1
    load_balancer_target_group_arn = ""
}

data "aws_caller_identity" "scheduler" {
  
}

resource "aws_iam_policy" "ecs-instance-scheduler-extra-policy" {
  name        = "scheduler-extra-policy"
  description = "Allows the scheduler to read parameters, write to the scheduler queue, read from the scheduler response queue, and get the number of messages in each of the 3 queues"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.scheduler.account_id}:parameter/${var.environment}/scheduler/*"
    },
    {
      "Action": [
        "sqs:SendMessageBatch",
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${module.scheduler_queue.queue_arn}"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessageBatch",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${module.scheduler_response_queue.queue_arn}"
    },
    {
      "Action": [
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${var.ingester_database_queue_arn}"
    },
    {
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}