variable "environment" {}
variable "region" {}
variable "metrics_namespace" {}
variable "topic_name" {}
variable "alarms_email" {}
variable "enable_alarms" {}
variable "unhandled_exceptions_threshold" {}
variable "dead_letter_queue_items_threshold" {}
variable "scheduler_users_store_exception_threshold" {}
variable "api_server_favorites_store_exception_threshold" {}
variable "api_server_generic_exception_threshold" {}
variable "process_names" { 
    type = "list" 
    default = ["api-server", "scheduler", "puller-flickr", "ingester-database"]
}
variable "dead_letter_queue_names" { type = "list" }