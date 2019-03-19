module "memcached" {
    source = "../../modules/memcached"

    environment = "${var.environment}"
    memcached_cluster_prefix = "puller-flickr"
    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    memcached_az_mode = "cross-az"
    memcached_security_group_ids = "sg-06aae46886ac00501" # FIXME: Create this security group with terraform and pass the ID here rather than hardcoding
}