variable "environment" {}
variable "region" {}
variable "mysql_instance_type" {}
variable "mysql_database_size_gb" {}
variable "mysql_storage_type" {}
variable "mysql_multi_az" {}
variable "mysql_database_password" {}
variable "mysql_backup_retention_period_days" {}
variable "mysql_storage_encrypted" {}
variable "mysql_database_batch_size" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }
variable "local_machine_cidr" {}
variable "ecs_instances_desired_count" {}
variable "ecs_instances_memory" {}
variable "ecs_instances_cpu" {}
variable "ecs_cluster_id" {}
variable "ecs_instances_log_configuration" {}
variable "ecs_instances_role_name" {}
variable "input_queue_batch_size" {}
variable "input_queue_max_items_to_process" {}