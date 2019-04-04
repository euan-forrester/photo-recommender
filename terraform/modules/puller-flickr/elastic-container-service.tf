module "elastic-container-service" {
    source = "../elastic-container-service"

    cluster_name = "puller-flickr-${var.environment}"
    region = "${var.region}"
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
}