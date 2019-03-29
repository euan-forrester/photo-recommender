data "aws_ecs_task_definition" "task" {
    task_definition = "${aws_ecs_task_definition.task.family}"
}

resource "aws_ecs_task_definition" "task" {
    family                = "${var.cluser_name}"
    container_definitions = <<DEFINITION
[
  {
    "name": "wordpress",
    "links": [
      "mysql"
    ],
    "image": "wordpress",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "memory": 500,
    "cpu": 10
  },
  {
    "environment": [
      {
        "name": "MYSQL_ROOT_PASSWORD",
        "value": "password"
      }
    ],
    "name": "mysql",
    "image": "mysql",
    "cpu": 10,
    "memory": 500,
    "essential": true
  }
]
DEFINITION
}

resource "aws_ecs_service" "ecs-service" {
    name            = "ecs-service"
    iam_role        = "${aws_iam_role.ecs-service-role.name}"
    cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
    task_definition = "${aws_ecs_task_definition.wordpress.family}:${max("${aws_ecs_task_definition.wordpress.revision}", "${data.aws_ecs_task_definition.wordpress.revision}")}"
    desired_count   = "${var.cluster_desired_size}"
}