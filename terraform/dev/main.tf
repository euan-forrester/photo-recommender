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
    cluster_desired_size = 1
    cluster_min_size = 0
    cluster_max_size = 2
    instances_log_retention_days = 1
}

module "database" {
    source = "../modules/database"

    environment = "dev"
    region = "${var.region}"

    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr                = "${module.vpc.vpc_cidr_block}"
    local_machine_cidr      = "${var.local_machine_cidr}"

    mysql_database_name     = "photorecommender"
    mysql_instance_type     = "db.t2.micro" 
    mysql_storage_encrypted = false # db.t2.micro doesn't support encryption at rest -- needs to be at least db.t2.small
    mysql_storage_type      = "gp2" # General purpose SSD
    mysql_database_size_gb  = 5
    mysql_multi_az          = false # Disable database multi-AZ in dev to save billing charges
    mysql_backup_retention_period_days = 3

    mysql_database_password = "${var.database_password_dev}"
}

module "memcached" {
    source = "../modules/memcached"

    environment = "dev"
    region = "${var.region}"

    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr                = "${module.vpc.vpc_cidr_block}"
    local_machine_cidr      = "${var.local_machine_cidr}"

    memcached_node_type = "cache.t2.micro"
    memcached_num_cache_nodes = 1 # Set to 0 to disable memcached in dev to save billing charges
    memcached_az_mode = "single-az" # Single az in dev to save billing charges
}

module "scheduler" {
    source = "../modules/scheduler"

    environment = "dev"
    region = "${var.region}"
    metrics_namespace = "${var.metrics_namespace}"

    parameter_memcached_location = "${module.memcached.location}"

    ecs_cluster_id = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 0
    ecs_instances_memory = 64
    ecs_instances_cpu = 400
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    api_server_host = "${module.api_server.load_balancer_host}"
    api_server_port = "${module.api_server.load_balancer_port}"

    scheduler_seconds_between_user_data_updates = 7200

    scheduler_queue_batch_size = 10

    scheduler_response_queue_batch_size = 10
    scheduler_response_queue_max_items_to_process = 10000

    ingester_database_queue_url = "${module.ingester_database.ingester_queue_url}"
    ingester_database_queue_arn = "${module.ingester_database.ingester_queue_arn}"
}

module "puller_flickr" {
    source = "../modules/puller-flickr"

    environment = "dev"
    region = "${var.region}"
    metrics_namespace = "${var.metrics_namespace}"

    parameter_memcached_location = "${module.memcached.location}"

    memcached_location = "localhost:11211" # Disable cacheing Flickr API responses for now, so we can test performance
    memcached_ttl = 7200

    ecs_cluster_id = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 0
    ecs_instances_memory = 64
    ecs_instances_cpu = 400
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    flickr_api_key = "${var.flickr_api_key}"
    flickr_secret_key = "${var.flickr_secret_key}"
    flickr_user_id = "${var.flickr_user_id}"
    flickr_api_retries = 3
    flickr_api_favorites_max_per_call = 500
    flickr_api_favorites_max_to_get = 1000
    flickr_api_favorites_max_calls_to_make = 1

    output_queue_url = "${module.ingester_database.ingester_queue_url}"
    output_queue_arn = "${module.ingester_database.ingester_queue_arn}"
    output_queue_batch_size = 10

    scheduler_queue_url = "${module.scheduler.scheduler_queue_url}"
    scheduler_queue_arn = "${module.scheduler.scheduler_queue_arn}"
    scheduler_queue_batch_size = 1 # Each message takes a while to process, so hoarding a bunch of messages in an individual instance means that other instances may be underutilized
    scheduler_queue_max_items_to_process = 1000

    scheduler_response_queue_url = "${module.scheduler.scheduler_response_queue_url}"
    scheduler_response_queue_arn = "${module.scheduler.scheduler_response_queue_arn}"
    scheduler_response_queue_batch_size = 10
}

module "ingester_database" {
    source = "../modules/ingester-database"

    environment             = "dev"
    region                  = "${var.region}"
    metrics_namespace       = "${var.metrics_namespace}"

    parameter_memcached_location = "${module.memcached.location}"

    ecs_cluster_id          = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 0
    ecs_instances_memory    = 64
    ecs_instances_cpu       = 400
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    mysql_database_host     = "${module.database.database_host}"
    mysql_database_port     = "${module.database.database_port}"
    mysql_database_username = "${module.database.database_username}"
    mysql_database_password = "${var.database_password_dev}"
    mysql_database_name     = "${module.database.database_name}"
    mysql_database_min_batch_size = 500
    mysql_database_maxretries = 3

    input_queue_batch_size  = 1 # Each message takes a while to process because it contains many individual items, so only get one at a time so that we're not blocking other instances from picking them up
    input_queue_max_items_to_process = 10000
}

module "api_server" {
    source = "../modules/api-server"

    environment             = "dev"
    region                  = "${var.region}"
    metrics_namespace       = "${var.metrics_namespace}"

    parameter_memcached_location = "${module.memcached.location}"

    vpc_id                  = "${module.vpc.vpc_id}"
    vpc_public_subnet_ids   = "${module.vpc.vpc_public_subnet_ids}"
    vpc_cidr                = "${module.vpc.vpc_cidr_block}"

    load_balancer_port      = 4444
    api_server_port         = 4445

    load_balancer_days_to_keep_access_logs = 1
    load_balancer_access_logs_bucket = "api-server-access-logs-dev"
    load_balancer_access_logs_prefix = "api-server-lb-dev"

    local_machine_cidr      = "${var.local_machine_cidr}"

    mysql_database_host     = "${module.database.database_host}"
    mysql_database_port     = "${module.database.database_port}"
    mysql_database_username = "${module.database.database_username}"
    mysql_database_password = "${var.database_password_dev}"
    mysql_database_name     = "${module.database.database_name}"
    mysql_database_fetch_batch_size = 10000
    mysql_database_connection_pool_size = 10

    ecs_cluster_id          = "${module.elastic_container_service.cluster_id}"
    ecs_instances_role_name = "${module.elastic_container_service.instance_role_name}"
    ecs_instances_desired_count = 1
    ecs_instances_memory    = 256
    ecs_instances_cpu       = 100
    ecs_instances_log_configuration = "${module.elastic_container_service.cluster_log_configuration}"
    ecs_days_to_keep_images = 1

    default_num_photo_recommendations = 10
}

module "dashboard" {
    source = "../modules/dashboard"

    environment = "dev"
    region      = "${var.region}"
    metrics_namespace = "${var.metrics_namespace}"

    scheduler_queue_base_name               = "${module.scheduler.scheduler_queue_base_name}"
    scheduler_queue_full_name               = "${module.scheduler.scheduler_queue_full_name}"
    scheduler_queue_dead_letter_full_name   = "${module.scheduler.scheduler_queue_dead_letter_full_name}"

    scheduler_response_queue_base_name              = "${module.scheduler.scheduler_response_queue_base_name}"
    scheduler_response_queue_full_name              = "${module.scheduler.scheduler_response_queue_full_name}"
    scheduler_response_queue_dead_letter_full_name  = "${module.scheduler.scheduler_response_queue_dead_letter_full_name}"

    ingester_queue_base_name                = "${module.ingester_database.ingester_queue_base_name}"
    ingester_queue_full_name                = "${module.ingester_database.ingester_queue_full_name}"
    ingester_queue_dead_letter_full_name    = "${module.ingester_database.ingester_queue_dead_letter_full_name}"

    database_identifier                     = "${module.database.database_instance_identifier}"

    ecs_autoscaling_group_name              = "${module.elastic_container_service.autoscaling_group_name}"
    ecs_cluster_name                        = "${module.elastic_container_service.cluster_full_name}"
}

module "alarms" {
    source = "../modules/alarms"

    environment     = "dev"
    region          = "${var.region}"

    enable_alarms   = "true"

    metrics_namespace = "${var.metrics_namespace}"
    topic_name      = "photo-recommender"
    alarms_email    = "${var.alarms_email}"

    unhandled_exceptions_threshold = 1

    queue_names = [ "${module.scheduler.scheduler_queue_full_name}", "${module.scheduler.scheduler_response_queue_full_name}", "${module.ingester_database.ingester_queue_full_name}"]
    queue_item_size_threshold = 235520 # 230kB -- 256kB is the absolute max
    queue_item_age_threshold = 300 # 5 minutes
    queue_reader_error_threshold = 1
    queue_writer_error_threshold = 1

    dead_letter_queue_names = [ "${module.scheduler.scheduler_queue_dead_letter_full_name}", "${module.scheduler.scheduler_response_queue_dead_letter_full_name}", "${module.ingester_database.ingester_queue_dead_letter_full_name}"]
    dead_letter_queue_items_threshold = 1

    scheduler_users_store_exception_threshold = 1

    api_server_favorites_store_exception_threshold = 1
    api_server_generic_exception_threshold = 1
    
    ingester_database_batch_writer_exception_threshold = 1
    
    puller_flickr_max_batch_size_exceeded_error_threshold = 1
    puller_flickr_max_neighbors_exceeded_error_threshold = 1
    puller_flickr_max_flickr_api_exceptions_threshold = 1
}
