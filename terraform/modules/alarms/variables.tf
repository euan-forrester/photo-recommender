variable "environment" {}
variable "region" {}
variable "metrics_namespace" {}
variable "topic_name" {}
variable "alarms_email" {}
variable "unhandled_exceptions_threshold" {}
variable "dead_letter_queue_items_threshold" {}
variable "process_names" { 
    type = "list" 
    default = ["api-server", "scheduler", "puller-flickr", "ingester-database"]
}
variable "dead_letter_queue_names" { type = "list" }