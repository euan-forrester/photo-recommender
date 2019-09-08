output "ingester_queue_url" {
    value = "${module.input_sqs_queue.queue_url}"
    description = "The URL of the ingester queue"
}

output "ingester_queue_arn" {
    value = "${module.input_sqs_queue.queue_arn}"
    description = "The ARN of the ingester queue"
}

output "ingester_queue_base_name" {
    value = "${module.input_sqs_queue.queue_base_name}"
    description = "The base name of the ingester queue"
}

output "ingester_queue_full_name" {
    value = "${module.input_sqs_queue.queue_full_name}"
    description = "The full name of the ingester queue"
}

output "ingester_queue_dead_letter_full_name" {
    value = "${module.input_sqs_queue.queue_dead_letter_full_name}"
    description = "The full name of the ingester dead letter queue"
}

output "ingester_response_queue_url" {
    value = "${module.output_sqs_queue.queue_url}"
    description = "The URL of the ingester response queue"
}

output "ingester_response_queue_arn" {
    value = "${module.output_sqs_queue.queue_arn}"
    description = "The ARN of the ingester response queue"
}

output "ingester_response_queue_base_name" {
    value = "${module.output_sqs_queue.queue_base_name}"
    description = "The base name of the ingester response queue"
}

output "ingester_response_queue_full_name" {
    value = "${module.output_sqs_queue.queue_full_name}"
    description = "The full name of the ingester response queue"
}

output "ingester_response_queue_dead_letter_full_name" {
    value = "${module.output_sqs_queue.queue_dead_letter_full_name}"
    description = "The full name of the ingester response dead letter queue"
}
