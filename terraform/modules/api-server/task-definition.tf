module "task_definition" {
    source = "../task-definition"

    name                        = "api-server-${var.environment}"
    environment                 = "${var.environment}"
    region                      = "${var.region}"
    container_repository_url    = "${module.container_repository.repository_url}"
    cluster_id                  = "${var.ecs_cluster_id}"
    instances_memory            = "${var.ecs_instances_memory}"
    instances_cpu               = "${var.ecs_instances_cpu}"
    instances_log_configuration = "${var.ecs_instances_log_configuration}"
    instances_desired_count     = "${var.ecs_instances_desired_count}"
    instances_role_name         = "${var.ecs_instances_role_name}"
    instances_extra_policy_arn  = "${aws_iam_policy.ecs-instance-api-server-extra-policy.arn}"
    port_mappings               = "${data.template_file.port_mappings.rendered}"
}

data "aws_caller_identity" "api-server" {
  
}

resource "aws_iam_policy" "ecs-instance-api-server-extra-policy" {
  name        = "api-server-extra-policy"
  description = "Allows api-server to read parameters and talk to the favorites database"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.api-server.account_id}:parameter/${var.environment}/api-server/*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "${aws_kms_key.parameter_secrets.arn}"
    }
  ]
}
EOF
}

# Part of a task definition, used in the task-definition module
data "template_file" "port_mappings" {
    template = <<EOF
    "portMappings": [
      {
        "containerPort": ${var.api_server_port},
        "hostPort": ${var.api_server_port}
      }
    ],
EOF
}