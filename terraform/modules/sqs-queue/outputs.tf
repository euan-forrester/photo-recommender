output "queue_url" {
    value = "${aws_sqs_queue.queue.id}"
    description = "The URL of the main queue created"
}

output "queue_arn" {
    value = "${aws_sqs_queue.queue.arn}"
    description = "The ARN of the main queue created"
}