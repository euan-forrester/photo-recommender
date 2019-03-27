module "puller-flickr" {
    source = "../modules/puller-flickr"

    environment = "dev"
    region = "${var.region}"
    availability_zone = "${var.availability_zone}"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    memcached_az_mode = "cross-az"

    local_machine_cidr = "${var.local_machine_cidr}"

    ecs_node_type = "t2.micro"
    ecs_cluster_min_size = 1
    ecs_cluster_max_size = 2
    ecs_cluster_desired_size = 2
}