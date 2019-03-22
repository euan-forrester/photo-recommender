module "dev" {
    source = "../kubernetes"

    cluster-name = "puller-flickr-${var.environment}"
    local_machine_cidr = "${var.local_machine_cidr}"
}