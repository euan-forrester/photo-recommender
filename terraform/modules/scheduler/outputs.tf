output "scheduler_queue_url" {
    value = "${module.scheduler_queue.queue_url}"
    description = "The URL of the scheduler queue"
}

output "scheduler_queue_arn" {
    value = "${module.scheduler_queue.queue_arn}"
    description = "The ARN of the scheduler queue"
}

output "scheduler_response_queue_url" {
    value = "${module.scheduler_response_queue.queue_url}"
    description = "The URL of the scheduler response queue"
}

output "scheduler_response_queue_arn" {
    value = "${module.scheduler_response_queue.queue_arn}"
    description = "The ARN of the scheduler response queue"
}

