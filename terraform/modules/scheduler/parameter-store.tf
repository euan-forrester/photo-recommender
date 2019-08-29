resource "aws_ssm_parameter" "metrics_namespace" {
    name        = "/${var.environment}/scheduler/metrics-namespace"
    description = "Namespace that our metrics go in"
    type        = "String"
    value       = "${var.metrics_namespace}"
}

resource "aws_ssm_parameter" "parameter_memcached_location" {
    name        = "/${var.environment}/scheduler/parameter-memcached-location"
    description = "Where to find a memcached instance to cache our parameter values"
    type        = "String"
    value       = "${var.parameter_memcached_location}"
}

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

resource "aws_ssm_parameter" "puller_queue_url" {
    name        = "/${var.environment}/scheduler/puller-queue-url"
    description = "URL of the queue to put requests for data to be pulled"
    type        = "String"
    value       = "${module.puller_queue.queue_url}"
}

resource "aws_ssm_parameter" "puller_queue_batch_size" {
    name        = "/${var.environment}/scheduler/puller-queue-batchsize"
    description = "Number of items to put on the puller queue in a single batch"
    type        = "String"
    value       = "${var.puller_queue_batch_size}"
}

resource "aws_ssm_parameter" "puller_response_queue_url" {
    name        = "/${var.environment}/scheduler/puller-response-queue-url"
    description = "Endpoint of queue we use to ingest responses about successful data pulling"
    type        = "String"
    value       = "${module.puller_response_queue.queue_url}"
}

resource "aws_ssm_parameter" "scheduler_seconds_between_user_data_updates" {
    name        = "/${var.environment}/scheduler/seconds-between-user-data-updates"
    description = "Number of seconds between requests from the scheduler to update user data from each provider"
    type        = "String"
    value       = "${var.scheduler_seconds_between_user_data_updates}"
}

resource "aws_ssm_parameter" "ingester_queue_url" {
    name        = "/${var.environment}/scheduler/ingester-queue-url"
    description = "Endpoint of queue we use to ingest data into the database, only used to check its size"
    type        = "String"
    value       = "${var.ingester_database_queue_url}"
}

resource "aws_ssm_parameter" "max_iterations_before_exit" {
    name        = "/${var.environment}/scheduler/max-iterations-before-exit"
    description = "Number of times we iterate over our tasks before exiting and being restarted"
    type        = "String"
    value       = "${var.max_iterations_before_exit}"
}

resource "aws_ssm_parameter" "sleep_ms_between_iterations" {
    name        = "/${var.environment}/scheduler/sleep-ms-between-iterations"
    description = "Number of milliseconds we sleep between iterations"
    type        = "String"
    value       = "${var.sleep_ms_between_iterations}"
}

resource "aws_ssm_parameter" "duration_to_request_lock_seconds" {
    name        = "/${var.environment}/scheduler/duration-to-request-lock-seconds"
    description = "Number of seconds for which to request a lock on other scheduler instances beginning processing"
    type        = "String"
    value       = "${var.duration_to_request_lock_seconds}"
}
