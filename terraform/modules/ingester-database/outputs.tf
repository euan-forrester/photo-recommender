output "ingester_queue_url" {
    value = "${module.sqs_queue.queue_url}"
    description = "The URL of the ingester queue"
}

output "ingester_queue_arn" {
    value = "${module.sqs_queue.queue_arn}"
    description = "The ARN of the ingester queue"
}

output "ingester_queue_base_name" {
    value = "${module.sqs_queue.queue_base_name}"
    description = "The base name of the ingester queue"
}

output "ingester_queue_full_name" {
    value = "${module.sqs_queue.queue_full_name}"
    description = "The full name of the ingester queue"
}

output "ingester_queue_dead_letter_full_name" {
    value = "${module.sqs_queue.queue_dead_letter_full_name}"
    description = "The full name of the ingester dead letter queue"
}

output "output_database_host" {
    value = "${module.mysql.database_host}"
    description = "Host string for the database that was created"
}

output "output_database_port" {
    value = "${module.mysql.database_port}"
    description = "Port for the database that was created"
}

output "output_database_username" {
    value = "${module.mysql.database_username}"
    description = "Username for the database that was created"
}

output "output_database_name" {
    value = "${module.mysql.database_name}"
    description = "Name of the database that was created"
}
