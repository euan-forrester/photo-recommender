variable "environment" {}
variable "region" {}
variable "topic_name" {}
variable "alarms_email" {}
variable "unhandled_exceptions_threshold" {}
variable "process_names" { 
    type = "list" 
    default = ["api-server", "scheduler", "puller-flickr", "ingester-database"]
}