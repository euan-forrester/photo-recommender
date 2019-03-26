module "kubernetes" {
    source = "../kubernetes"

    cluster_name = "puller-flickr-${var.environment}"
    local_machine_cidr = "${var.local_machine_cidr}"
    node_type = "${var.kubernetes_node_type}"

    cluster_min_size = "${var.kubernetes_cluster_min_size}"
    cluster_max_size = "${var.kubernetes_cluster_max_size}"
    cluster_desired_size = "${var.kubernetes_cluster_desired_size}"
}