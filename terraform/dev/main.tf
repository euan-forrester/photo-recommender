module "vpc" {
    source = "../modules/vpc"

    vpc_name = "photo-recommender"
    environment = "dev"
    availability_zone_1 = "${var.availability_zone_1}"
    availability_zone_2 = "${var.availability_zone_2}"
}

module "puller-flickr" {
    source = "../modules/puller-flickr"

    environment = "dev"
    region = "${var.region}"

    vpc_id = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids = "${module.vpc.vpc_public_subnet_ids}"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 2
    memcached_az_mode = "cross-az"
    memcached_ttl = 7200

    local_machine_cidr = "${var.local_machine_cidr}"
    local_machine_public_key = "${var.local_machine_public_key}"

    ecs_instance_type = "t2.micro"
    ecs_cluster_desired_size = 1
    ecs_cluster_min_size = 1
    ecs_cluster_max_size = 2
    ecs_instances_desired_count = 0
    ecs_instances_memory = 256
    ecs_instances_cpu = 1
    ecs_instances_log_retention_days = 1

    flickr_api_key = "${var.flickr_api_key}"
    flickr_secret_key = "${var.flickr_secret_key}"
    flickr_user_id = "${var.flickr_user_id}"
    flickr_api_retries = 3
    flickr_api_favorites_max_per_call = 500
    flickr_api_favorites_max_to_get = 1000

    output_queue_url = "${module.ingester_database.ingester_queue_url}"
    output_queue_arn = "${module.ingester_database.ingester_queue_arn}"
    output_queue_batch_size = 10
}

module "ingester_database" {
    source = "../modules/ingester-database"

    environment             = "dev"
    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    local_machine_cidr      = "${var.local_machine_cidr}"

    mysql_instance_type     = "db.t2.small" # db.t2.micro doesn't support encryption at rest
    mysql_storage_type      = "standard" # Magnetic storage; min size 5GB
    mysql_database_size_gb  = 5
    mysql_multi_az          = true
    mysql_backup_retention_period_days = 3

    mysql_database_password = "${var.database_password_dev}"
}