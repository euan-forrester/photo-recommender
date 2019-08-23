variable "environment" {}
variable "region" {}
variable "metrics_namespace" {}

variable "puller_queue_base_name" {}
variable "puller_queue_full_name" {}
variable "puller_queue_dead_letter_full_name" {}

variable "puller_response_queue_base_name" {}
variable "puller_response_queue_full_name" {}
variable "puller_response_queue_dead_letter_full_name" {}

variable "ingester_queue_base_name" {}
variable "ingester_queue_full_name" {}
variable "ingester_queue_dead_letter_full_name" {}

variable "database_identifier" {}

variable "ecs_autoscaling_group_name" {}
variable "ecs_cluster_name" {}