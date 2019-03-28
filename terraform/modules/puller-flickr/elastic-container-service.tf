module "elastic-container-service" {
    source = "../elastic-container-service"

    environment = "${var.environment}"
    cluster_name = "puller-flickr-${var.environment}"
    region = "${var.region}"
    availability_zone = "${var.availability_zone}"

    local_machine_cidr = "${var.local_machine_cidr}"
    local_machine_public_key = "${var.local_machine_public_key}"
    
    instance_type = "${var.ecs_instance_type}"

    cluster_desired_size = "${var.ecs_cluster_desired_size}"
}