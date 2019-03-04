module "memcached" {
    source = "../../modules/memcached"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    environment = "${var.environment}"
}