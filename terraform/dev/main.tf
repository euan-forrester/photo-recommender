module "dev" {
    source = "../modules/puller-flickr"

    environment = "dev"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    memcached_az_mode = "cross-az"

    local_machine_cidr = "${var.local_machine_cidr}"
}