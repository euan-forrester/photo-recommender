module "dev" {
    source = "../kubernetes"

    cluster_name = "puller-flickr-${var.environment}"
    local_machine_cidr = "${var.local_machine_cidr}"
}