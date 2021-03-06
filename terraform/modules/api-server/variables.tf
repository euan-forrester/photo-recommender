variable "environment" {
}

variable "region" {
}

variable "metrics_namespace" {
}

variable "parameter_memcached_location" {
}

variable "mysql_database_host" {
}

variable "mysql_database_port" {
}

variable "mysql_database_username" {
}

variable "mysql_database_password" {
}

variable "mysql_database_name" {
}

variable "mysql_database_fetch_batch_size" {
}

variable "mysql_database_connection_pool_size" {
}

variable "mysql_database_user_data_encryption_key" {
}

variable "vpc_id" {
}

variable "vpc_public_subnet_ids" {
  type = list(string)
}

variable "vpc_cidr" {
}

variable "ecs_instances_desired_count" {
}

variable "ecs_instances_memory" {
}

variable "ecs_instances_cpu" {
}

variable "ecs_cluster_id" {
}

variable "ecs_instances_log_configuration" {
}

variable "ecs_instances_role_name" {
}

variable "ecs_days_to_keep_images" {
}

variable "local_machine_cidr" {
}

variable "api_server_port" {
}

variable "session_encryption_key" {
}

variable "load_balancer_port" {
}

variable "load_balancer_days_to_keep_access_logs" {
}

variable "load_balancer_access_logs_bucket" {
}

variable "load_balancer_access_logs_prefix" {
}

variable "bucketname_user_string" {
}

variable "retain_load_balancer_access_logs_after_destroy" {
  type = bool
}

variable "default_num_photo_recommendations" {
}

variable "default_num_user_recommendations" {
}

variable "default_num_photos_from_group" {
}

variable "flickr_api_key" {
}

variable "flickr_secret_key" {
}

variable "flickr_api_retries" {
}

variable "flickr_api_memcached_location" {
}

variable "flickr_api_memcached_ttl" {
}

variable "flickr_auth_memcached_location" {
}

variable "puller_queue_batch_size" {
}

variable "puller_queue_url" {
}

variable "puller_queue_arn" {
}

variable "process_name" {
}

variable "project_github_location" {
}

variable "build_logs_bucket_id" {
}

variable "buildspec_location" {
}

variable "file_path" {
}

variable "file_path_common" {
}

variable "build_service_role_arn" {
}

variable "kms_key_id" {
}

variable "kms_key_arn" {
}

