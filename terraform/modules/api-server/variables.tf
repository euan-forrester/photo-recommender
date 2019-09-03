variable "environment" {}
variable "region" {}
variable "metrics_namespace" {}
variable "parameter_memcached_location" {}
variable "mysql_database_host" {}
variable "mysql_database_port" {}
variable "mysql_database_username" {}
variable "mysql_database_password" {}
variable "mysql_database_name" {}
variable "mysql_database_fetch_batch_size" {}
variable "mysql_database_connection_pool_size" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }
variable "vpc_cidr" {}
variable "ecs_instances_desired_count" {}
variable "ecs_instances_memory" {}
variable "ecs_instances_cpu" {}
variable "ecs_cluster_id" {}
variable "ecs_instances_log_configuration" {}
variable "ecs_instances_role_name" {}
variable "ecs_days_to_keep_images" {}
variable "local_machine_cidr" {}
variable "api_server_port" {}
variable "load_balancer_port" {}
variable "load_balancer_days_to_keep_access_logs" {}
variable "load_balancer_access_logs_bucket" {}
variable "load_balancer_access_logs_prefix" {}
variable "retain_load_balancer_access_logs_after_destroy" {}
variable "default_num_photo_recommendations" {}
variable "flickr_api_key" {}
variable "flickr_secret_key" {}
variable "flickr_api_retries" {}
variable "flickr_api_memcached_location" {}
variable "flickr_api_memcached_ttl" {}