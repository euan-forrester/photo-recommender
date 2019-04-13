variable "cluster_name" {}
variable "region" {}
variable "environment" {}
variable "local_machine_cidr" {}
variable "instance_type" {}
variable "cluster_desired_size" {}
variable "cluster_min_size" {}
variable "cluster_max_size" {}
variable "local_machine_public_key" {}
variable "instances_desired_count" {}
variable "instances_memory" {}
variable "instances_cpu" {}
variable "instances_log_retention_days" {}
variable "instances_extra_policy_arn" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }