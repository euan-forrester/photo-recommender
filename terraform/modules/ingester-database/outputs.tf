output "ingester_queue_url" {
    value = "${module.sqs_queue.queue_url}"
    description = "The URL of the ingester queue"
}