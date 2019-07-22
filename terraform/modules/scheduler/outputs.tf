output "scheduler_queue_url" {
    value = "${module.scheduler_queue.queue_url}"
    description = "The URL of the scheduler queue"
}

output "scheduler_queue_arn" {
    value = "${module.scheduler_queue.queue_arn}"
    description = "The ARN of the scheduler queue"
}

output "scheduler_queue_base_name" {
    value = "${module.scheduler_queue.queue_base_name}"
    description = "The base name of the scheduler queue"
}

output "scheduler_queue_full_name" {
    value = "${module.scheduler_queue.queue_full_name}"
    description = "The full name of the scheduler queue"
}

output "scheduler_queue_dead_letter_full_name" {
    value = "${module.scheduler_queue.queue_dead_letter_full_name}"
    description = "The full name of the scheduler dead letter queue"
}

output "scheduler_response_queue_url" {
    value = "${module.scheduler_response_queue.queue_url}"
    description = "The URL of the scheduler response queue"
}

output "scheduler_response_queue_arn" {
    value = "${module.scheduler_response_queue.queue_arn}"
    description = "The ARN of the scheduler response queue"
}

output "scheduler_response_queue_base_name" {
    value = "${module.scheduler_response_queue.queue_base_name}"
    description = "The base name of the scheduler response queue"
}

output "scheduler_response_queue_full_name" {
    value = "${module.scheduler_response_queue.queue_full_name}"
    description = "The full name of the scheduler response queue"
}

output "scheduler_response_queue_dead_letter_full_name" {
    value = "${module.scheduler_response_queue.queue_dead_letter_full_name}"
    description = "The full name of the scheduler response dead letter queue"
}