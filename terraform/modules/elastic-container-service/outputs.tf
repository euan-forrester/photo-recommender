output "cluster_id" {
    value = "${aws_ecs_cluster.ecs-cluster.id}"
    description = "The ID of the ECS cluster that was created"
}

output "cluster_log_configuration" {
    value = "${data.template_file.log_configuration.rendered}"
    description = "The log configuration for all of the tasks to run on this cluster"
}

output "instance_role_name" {
    value = "${aws_iam_role.ecs-instance-role.name}"
    description = "The name of the role assigned to each instance in the cluster. Attach extra policies needed by your task here."
}

output "autoscaling_group_name" {
    value = "${aws_autoscaling_group.ecs-autoscaling-group.name}"
    description = "The name of the autoscaling group that was created"
}