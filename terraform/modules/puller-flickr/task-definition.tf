data "aws_ecs_task_definition" "puller_flickr_task" {
    depends_on = [ "aws_ecs_task_definition.puller_flickr_task" ] # https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    task_definition = "${aws_ecs_task_definition.puller_flickr_task.family}"
}

data "aws_caller_identity" "puller_flickr" {
  
}

# NOTE: to debug issues with this JSON, try targetting this specific resource when running terraform. 
# Otherwise you will get a generic and confusing error message 
# (example: "Resource 'aws_ecs_task_definition.puller_flickr_task' not found for variable 'aws_ecs_task_definition.puller_flickr_task.family'").
# e.g. `terraform plan -target=module.puller-flickr.aws_ecs_task_definition.puller_flickr_task`. 
# See https://github.com/terraform-providers/terraform-provider-aws/issues/3281

resource "aws_ecs_task_definition" "puller_flickr_task" {
    family                = "puller-flickr"
    container_definitions = <<DEFINITION
[
  {
    "name": "puller-flickr-${var.environment}",
    "image": "${aws_ecr_repository.ecr.repository_url}:latest",
    "essential": true,
    "memory": ${var.ecs_instances_memory},
    "cpu": ${var.ecs_instances_cpu},
    "environment": [
      { "name": "ENVIRONMENT", "value": "${var.environment}" },
      { "name": "AWS_DEFAULT_REGION", "value": "${var.region}" }
    ],
    ${var.ecs_instances_log_configuration}
  }
]
DEFINITION

    # Consider putting this in if we see this stuff getting rebuilt every run when we don't want to. 
    # Note then that there will be an extra step when we change the task definition: https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    #lifecycle {
    #    ignore_changes = [
    #      "container_definitions" # if template file changed, do nothing, believe that human's changes are source of truth
    #    ]
    #}
}

resource "aws_ecs_service" "puller_flickr" {
    name            = "puller-flickr-${var.environment}"
    cluster         = "${var.ecs_cluster_id}"
    task_definition = "${aws_ecs_task_definition.puller_flickr_task.family}:${max("${aws_ecs_task_definition.puller_flickr_task.revision}", "${data.aws_ecs_task_definition.puller_flickr_task.revision}")}"
    desired_count   = "${var.ecs_instances_desired_count}"

    # Consider putting this in if we see this stuff getting rebuilt every run when we don't want to. 
    # Note then that there will be an extra step when we change the task definition: https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    #lifecycle {
    #    ignore_changes = ["task_definition"] # the same here, do nothing if it was already installed
    #}
}

# Add extra permissions to the instances in the cluster to support the actions puller-flickr needs to take
resource "aws_iam_role_policy_attachment" "attach-extra-policy" {
    role       = "${var.ecs_instance_role_name}"
    policy_arn = "${aws_iam_policy.ecs-instance-puller-flickr-extra-policy.arn}"
}

resource "aws_iam_policy" "ecs-instance-puller-flickr-extra-policy" {
  name        = "puller-flickr-extra-policy"
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