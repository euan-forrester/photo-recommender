module "vpc" {
    source = "../modules/vpc"

    vpc_name = "photo-recommender"
    environment = "dev"

    cidr_block = "10.10.0.0/16"

    subnets = {
        us-west-2a = "10.10.1.0/24"
        us-west-2b = "10.10.2.0/24"
    }
}

module "elastic_container_service" {
    source = "../modules/elastic-container-service"

    environment = "dev"
    region = "${var.region}"
    cluster_name = "photo-recommender"

    vpc_id = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids = "${module.vpc.vpc_public_subnet_ids}"

    local_machine_cidr = "${var.local_machine_cidr}"
    local_machine_public_key = "${var.local_machine_public_key}"

    extra_security_groups = ["${module.api_server.security_group_id}"]

    instance_type = "t2.micro"
    cluster_desired_size = 2
    cluster_min_size = 1
    cluster_max_size = 2
    instances_log_retention_days = 1
}

module "scheduler" {
    source = "../modules/scheduler"

    environment = "dev"
    region = "${var.region}"

    ecs_cluster_id = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 1
    ecs_instances_memory = 32
    ecs_instances_cpu = 1
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    api_server_host = "${module.api_server.load_balancer_host}"
    api_server_port = "${module.api_server.load_balancer_port}"

    scheduler_seconds_between_user_data_updates = 7200

    scheduler_queue_batch_size = 10

    scheduler_response_queue_batch_size = 10
    scheduler_response_queue_max_items_to_process = 10000
}

module "puller_flickr" {
    source = "../modules/puller-flickr"

    environment = "dev"
    region = "${var.region}"

    vpc_id = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr = "${module.vpc.vpc_cidr_block}"
    local_machine_cidr = "${var.local_machine_cidr}"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 0 # Disable memcached in dev to save billing charges
    memcached_az_mode = "cross-az"
    memcached_ttl = 7200

    ecs_cluster_id = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 10
    ecs_instances_memory = 64
    ecs_instances_cpu = 1
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    flickr_api_key = "${var.flickr_api_key}"
    flickr_secret_key = "${var.flickr_secret_key}"
    flickr_user_id = "${var.flickr_user_id}"
    flickr_api_retries = 3
    flickr_api_favorites_max_per_call = 500
    flickr_api_favorites_max_to_get = 1000

    output_queue_url = "${module.ingester_database.ingester_queue_url}"
    output_queue_arn = "${module.ingester_database.ingester_queue_arn}"
    output_queue_batch_size = 10

    scheduler_queue_url = "${module.scheduler.scheduler_queue_url}"
    scheduler_queue_arn = "${module.scheduler.scheduler_queue_arn}"
    scheduler_queue_batch_size = 10
    scheduler_queue_max_items_to_process = 1000

    scheduler_response_queue_url = "${module.scheduler.scheduler_response_queue_url}"
    scheduler_response_queue_arn = "${module.scheduler.scheduler_response_queue_arn}"
    scheduler_response_queue_batch_size = 10
}

module "ingester_database" {
    source = "../modules/ingester-database"

    environment             = "dev"
    region                  = "${var.region}"

    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr                = "${module.vpc.vpc_cidr_block}"
    local_machine_cidr      = "${var.local_machine_cidr}"

    mysql_instance_type     = "db.t2.micro" 
    mysql_storage_encrypted = false # db.t2.micro doesn't support encryption at rest -- needs to be at least db.t2.small
    mysql_storage_type      = "standard" # Magnetic storage; min size 5GB
    mysql_database_size_gb  = 5
    mysql_multi_az          = false # Disable database multi-AZ in dev to save billing charges
    mysql_backup_retention_period_days = 3
    mysql_database_batch_size = 1000

    mysql_database_password = "${var.database_password_dev}"

    ecs_cluster_id          = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 10
    ecs_instances_memory    = 64
    ecs_instances_cpu       = 1
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    input_queue_batch_size  = 10
    input_queue_max_items_to_process = 10000
}

module "api_server" {
    source = "../modules/api-server"

    environment             = "dev"
    region                  = "${var.region}"

    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr                = "${module.vpc.vpc_cidr_block}"

    load_balancer_port      = 4444
    api_server_port         = 4445

    load_balancer_days_to_keep_access_logs = 1
    load_balancer_access_logs_bucket = "api-server-access-logs-dev"
    load_balancer_access_logs_prefix = "api-server-lb-dev"

    local_machine_cidr      = "${var.local_machine_cidr}"

    mysql_database_host     = "${module.ingester_database.output_database_host}"
    mysql_database_port     = "${module.ingester_database.output_database_port}"
    mysql_database_username = "${module.ingester_database.output_database_username}"
    mysql_database_password = "${var.database_password_dev}"
    mysql_database_name     = "${module.ingester_database.output_database_name}"
    mysql_database_fetch_batch_size = 10000
    mysql_database_connection_pool_size = 10

    ecs_cluster_id          = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 1
    ecs_instances_memory    = 256
    ecs_instances_cpu       = 1
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    default_num_photo_recommendations = 10
}

module "dashboard" {
    source = "../modules/dashboard"

    environment             = "dev"
    region                  = "${var.region}"

    scheduler_queue_base_name               = "${module.scheduler.scheduler_queue_base_name}"
    scheduler_queue_full_name               = "${module.scheduler.scheduler_queue_full_name}"
    scheduler_queue_dead_letter_full_name   = "${module.scheduler.scheduler_queue_dead_letter_full_name}"

    scheduler_response_queue_base_name              = "${module.scheduler.scheduler_response_queue_base_name}"
    scheduler_response_queue_full_name              = "${module.scheduler.scheduler_response_queue_full_name}"
    scheduler_response_queue_dead_letter_full_name  = "${module.scheduler.scheduler_response_queue_dead_letter_full_name}"

    ingester_queue_base_name               = "${module.ingester_database.ingester_queue_base_name}"
    ingester_queue_full_name               = "${module.ingester_database.ingester_queue_full_name}"
    ingester_queue_dead_letter_full_name   = "${module.ingester_database.ingester_queue_dead_letter_full_name}"
}

