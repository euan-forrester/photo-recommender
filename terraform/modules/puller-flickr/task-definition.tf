module "task_definition" {
  source = "../task-definition"

  name                           = "puller-flickr-${var.environment}"
  environment                    = var.environment
  region                         = var.region
  container_repository_url       = module.container_repository.repository_url
  cluster_id                     = var.ecs_cluster_id
  instances_memory               = var.ecs_instances_memory
  instances_cpu                  = var.ecs_instances_cpu
  instances_log_configuration    = var.ecs_instances_log_configuration
  instances_desired_count        = var.ecs_instances_desired_count
  instances_role_name            = var.ecs_instances_role_name
  instances_extra_policy_arn     = aws_iam_policy.ecs-instance-puller-flickr-extra-policy.arn
  port_mappings                  = ""
  has_load_balancer              = false
  load_balancer_container_port   = -1
  load_balancer_target_group_arn = ""
}

data "aws_caller_identity" "puller_flickr" {
}

resource "aws_iam_policy" "ecs-instance-puller-flickr-extra-policy" {
  name        = "puller-flickr-extra-policy-${var.environment}"
  description = "Allows puller-flickr to read parameters and write to the ingestion queue"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.puller_flickr.account_id}:parameter/${var.environment}/puller-flickr/*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "${var.kms_key_arn}"
    },
    {
      "Action": [
        "sqs:SendMessageBatch",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${var.output_queue_arn}"
    },
    {
      "Action": [
        "sqs:SendMessageBatch",
        "sqs:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${var.puller_response_queue_arn}"
    },
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessageBatch",
        "sqs:DeleteMessage"
      ],
      "Effect": "Allow",
      "Resource": "${var.puller_queue_arn}"
    }
  ]
}
EOF

}

