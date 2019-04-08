output "queue_url" {
    value = "${aws_sqs_queue.queue.id}"
    description = "The URL of the main queue created"
}