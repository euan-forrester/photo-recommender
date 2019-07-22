output "queue_url" {
    value = "${aws_sqs_queue.queue.id}"
    description = "The URL of the main queue created"
}

output "queue_arn" {
    value = "${aws_sqs_queue.queue.arn}"
    description = "The ARN of the main queue created"
}

output "queue_base_name" {
    value = "${var.queue_name}"
    description = "The base name of the queue (without environment)"
}

output "queue_full_name" {
    value = "${var.queue_name}-${var.environment}"
    description = "The full name of the queue (with environment)"
}

output "queue_dead_letter_full_name" {
    value = "${var.queue_name}-dead-letter-${var.environment}"
    description = "The full name of the queue's dead letter queue (with environment)"
}