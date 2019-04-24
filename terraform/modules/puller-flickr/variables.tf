variable "environment" {}
variable "region" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }
variable "memcached_node_type" {}
variable "memcached_num_cache_nodes" {}
variable "memcached_az_mode" {}
variable "memcached_ttl" {}
variable "local_machine_cidr" {}
variable "vpc_cidr" {}
variable "ecs_instances_desired_count" {}
variable "ecs_instances_memory" {}
variable "ecs_instances_cpu" {}
variable "ecs_cluster_id" {}
variable "ecs_instances_log_configuration" {}
variable "ecs_instances_role_name" {}
variable "flickr_api_key" {}
variable "flickr_secret_key" {}
variable "flickr_user_id" {}
variable "flickr_api_retries" {}
variable "flickr_api_favorites_max_per_call" {}
variable "flickr_api_favorites_max_to_get" {}
variable "output_queue_url" {}
variable "output_queue_arn" {}
variable "output_queue_batch_size" {}