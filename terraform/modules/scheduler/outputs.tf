output "puller_queue_url" {
  value       = module.puller_queue.queue_url
  description = "The URL of the puller queue"
}

output "puller_queue_arn" {
  value       = module.puller_queue.queue_arn
  description = "The ARN of the puller queue"
}

output "puller_queue_base_name" {
  value       = module.puller_queue.queue_base_name
  description = "The base name of the puller queue"
}

output "puller_queue_full_name" {
  value       = module.puller_queue.queue_full_name
  description = "The full name of the puller queue"
}

output "puller_queue_dead_letter_full_name" {
  value       = module.puller_queue.queue_dead_letter_full_name
  description = "The full name of the puller dead letter queue"
}

output "puller_response_queue_url" {
  value       = module.puller_response_queue.queue_url
  description = "The URL of the puller response queue"
}

output "puller_response_queue_arn" {
  value       = module.puller_response_queue.queue_arn
  description = "The ARN of the puller response queue"
}

output "puller_response_queue_base_name" {
  value       = module.puller_response_queue.queue_base_name
  description = "The base name of the puller response queue"
}

output "puller_response_queue_full_name" {
  value       = module.puller_response_queue.queue_full_name
  description = "The full name of the puller response queue"
}

output "puller_response_queue_dead_letter_full_name" {
  value       = module.puller_response_queue.queue_dead_letter_full_name
  description = "The full name of the puller response dead letter queue"
}

