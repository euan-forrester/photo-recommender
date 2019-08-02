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
variable "queue_item_size_threshold" {}
variable "queue_item_age_threshold" {}
variable "process_names" { 
    type = "list" 
    default = ["api-server", "scheduler", "puller-flickr", "ingester-database"]
}
variable "queue_names" { type = "list" }
variable "dead_letter_queue_names" { type = "list" }