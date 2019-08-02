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
variable "queue_reader_error_threshold" {}
variable "queue_writer_error_threshold" {}
variable "ingester_database_batch_writer_exception_threshold" {}
variable "puller_flickr_max_batch_size_exceeded_error_threshold" {}
variable "puller_flickr_max_neighbors_exceeded_error_threshold" {}
variable "puller_flickr_max_flickr_api_exceptions_threshold" {}
variable "process_names" { 
    type = "list" 
    default = ["api-server", "scheduler", "puller-flickr", "ingester-database"]
}
variable "process_names_that_read_from_queues" { 
    type = "list" 
    default = ["scheduler", "puller-flickr", "ingester-database"]
}
variable "process_names_that_write_to_queues" { 
    type = "list" 
    default = ["scheduler", "puller-flickr"]
}
variable "queue_names" { type = "list" }
variable "dead_letter_queue_names" { type = "list" }
