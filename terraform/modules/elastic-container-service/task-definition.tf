data "aws_ecs_task_definition" "my_task" {
    depends_on = [ "aws_ecs_task_definition.my_task" ] # https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    task_definition = "${aws_ecs_task_definition.my_task.family}"
}

data "aws_caller_identity" "current" {
  
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.cluster_name}"
  retention_in_days = "${var.instances_log_retention_days}"
}

# NOTE: to debug issues with this JSON, try targetting this specific resource when running terraform. 
# Otherwise you will get a generic and confusing error message.
# e.g. `terraform plan -target=module.puller-flickr.elastic-container-service.aws_ecs_task_definition`. 

# TODO: Consider sending all logs to a single region so they can all be viewed together

resource "aws_ecs_task_definition" "my_task" {
    family                = "${var.cluster_name}"
    container_definitions = <<DEFINITION
[
  {
    "name": "${var.cluster_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.cluster_name}:latest",
    "essential": true,
    "memory": ${var.instances_memory},
    "cpu": ${var.instances_cpu},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S.%f %z",
        "awslogs-region": "${var.region}",
        "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
        "awslogs-stream-prefix": "${var.cluster_name}"
      }
    }
  }
]
DEFINITION

    # Considering putting this in if we see this stuff getting rebuilt every run when we don't want to. 
    # Note then that there will be an extra step when we change the task definition: https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    #lifecycle {
    #    ignore_changes = [
    #      "container_definitions" # if template file changed, do nothing, believe that human's changes are source of truth
    #    ]
    #}
}

resource "aws_ecs_service" "ecs-service" {
    name            = "ecs-service"
    cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
    task_definition = "${aws_ecs_task_definition.my_task.family}:${max("${aws_ecs_task_definition.my_task.revision}", "${data.aws_ecs_task_definition.my_task.revision}")}"
    desired_count   = "${var.instances_desired_count}"

    # Considering putting this in if we see this stuff getting rebuilt every run when we don't want to. 
    # Note then that there will be an extra step when we change the task definition: https://github.com/terraform-providers/terraform-provider-aws/issues/1274
    #lifecycle {
    #    ignore_changes = ["task_definition"] # the same here, do nothing if it was already installed
    #}
}