module "elastic-container-service" {
    source = "../elastic-container-service"

    environment = "${var.environment}"
    cluster_name = "puller-flickr-${var.environment}"
    region = "${var.region}"
    availability_zone = "${var.availability_zone}"

    local_machine_cidr = "${var.local_machine_cidr}"
    node_type = "${var.ecs_node_type}"

    cluster_min_size = "${var.ecs_cluster_min_size}"
    cluster_max_size = "${var.ecs_cluster_max_size}"
    cluster_desired_size = "${var.ecs_cluster_desired_size}"
}