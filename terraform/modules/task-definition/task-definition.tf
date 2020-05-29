data "aws_ecs_task_definition" "task_definition" {
  depends_on      = [aws_ecs_task_definition.task_definition] # https://github.com/terraform-providers/terraform-provider-aws/issues/1274
  task_definition = aws_ecs_task_definition.task_definition.family
}

# NOTE: to debug issues with this JSON, try targetting this specific resource when running terraform. 
# Otherwise you will get a generic and confusing error message 
# (example: "Resource 'aws_ecs_task_definition.task_definition' not found for variable 'aws_ecs_task_definition.task_definition.family'").
# e.g. `terraform plan -target=module.puller-flickr.task-definition.aws_ecs_task_definition.task_definition`. 
# See https://github.com/terraform-providers/terraform-provider-aws/issues/3281

resource "aws_ecs_task_definition" "task_definition" {
  family                = var.name
  container_definitions = <<DEFINITION
[
  {
    "name": "${var.name}",
    "image": "${var.container_repository_url}:latest",
    "essential": true,
    "memory": ${var.instances_memory},
    "cpu": ${var.instances_cpu},
    "environment": [
      { "name": "ENVIRONMENT", "value": "${var.environment}" },
      { "name": "AWS_DEFAULT_REGION", "value": "${var.region}" }
    ],
    ${var.port_mappings}
    ${var.instances_log_configuration}
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

# Add extra permissions to the instances in the cluster to support the actions puller-flickr needs to take
resource "aws_iam_role_policy_attachment" "attach-extra-policy" {
  role       = var.instances_role_name
  policy_arn = var.instances_extra_policy_arn
}

resource "aws_ecs_service" "ecs_service" {
  name    = var.name
  cluster = var.cluster_id
  task_definition = "${aws_ecs_task_definition.task_definition.family}:${max(
    aws_ecs_task_definition.task_definition.revision,
    data.aws_ecs_task_definition.task_definition.revision,
  )}"
  desired_count = var.instances_desired_count

  dynamic "load_balancer" {
    for_each = var.has_load_balancer ? [1] : []
    content {
      target_group_arn = var.load_balancer_target_group_arn
      container_name   = var.name
      container_port   = var.load_balancer_container_port
    }
  }
  # Consider putting this in if we see this stuff getting rebuilt every run when we don't want to. 
  # Note then that there will be an extra step when we change the task definition: https://github.com/terraform-providers/terraform-provider-aws/issues/1274
  #lifecycle {
  #    ignore_changes = ["task_definition"] # the same here, do nothing if it was already installed
  #}
}

