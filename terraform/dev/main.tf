module "dev" {
    source = "../modules/puller-flickr"

    environment = "dev"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    memcached_az_mode = "cross-az"

    local_machine_cidr = "${var.local_machine_cidr}"

    kubernetes_node_type = "t2.micro"
    kubernetes_cluster_min_size = 1
    kubernetes_cluster_max_size = 2
    kubernetes_cluster_desired_size = 2
}