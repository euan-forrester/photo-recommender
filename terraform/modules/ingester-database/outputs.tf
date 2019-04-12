output "ingester_queue_url" {
    value = "${module.sqs_queue.queue_url}"
    description = "The URL of the ingester queue"
}

output "ingester_queue_arn" {
    value = "${module.sqs_queue.queue_arn}"
    description = "The ARN of the ingester queue"
}