resource "aws_ssm_parameter" "api_server_host" {
    name        = "/${var.environment}/scheduler/api-server-host"
    description = "Host for API server from which we get scheduling information"
    type        = "String"
    value       = "${var.api_server_host}"
}

resource "aws_ssm_parameter" "api_server_port" {
    name        = "/${var.environment}/scheduler/api-server-port"
    description = "Port for the API server from which we get scheduling information"
    type        = "String"
    value       = "${var.api_server_port}"
}

resource "aws_ssm_parameter" "scheduler_queue_url" {
    name        = "/${var.environment}/scheduler/scheduler-queue-url"
    description = "URL of the queue to put requests for data to be pulled"
    type        = "String"
    value       = "${module.scheduler_queue.queue_url}"
}

resource "aws_ssm_parameter" "scheduler_queue_batch_size" {
    name        = "/${var.environment}/scheduler/scheduler-queue-batchsize"
    description = "Number of items to put on the scheduler queue in a single batch"
    type        = "String"
    value       = "${var.scheduler_queue_batch_size}"
}

resource "aws_ssm_parameter" "scheduler_response_queue_url" {
    name        = "/${var.environment}/scheduler/scheduler-response-queue-url"
    description = "Endpoint of queue we use to ingest responses about successful data pulling"
    type        = "String"
    value       = "${module.scheduler_response_queue.queue_url}"
}

resource "aws_ssm_parameter" "scheduler_response_queue_batch_size" {
    name        = "/${var.environment}/scheduler/scheduler-response-queue-batchsize"
    description = "Number of items to take off of the scheduler response queue in a single batch"
    type        = "String"
    value       = "${var.scheduler_response_queue_batch_size}"
}

resource "aws_ssm_parameter" "scheduler_response_queue_max_items_to_process" {
    name        = "/${var.environment}/scheduler/scheduler-response-queue-maxitemstoprocess"
    description = "Maximum number of items to take off the scheduler response queue before exiting"
    type        = "String"
    value       = "${var.scheduler_response_queue_max_items_to_process}"
}
