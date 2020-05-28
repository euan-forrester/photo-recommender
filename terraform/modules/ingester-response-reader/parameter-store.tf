resource "aws_ssm_parameter" "metrics_namespace" {
  name        = "/${var.environment}/ingester-response-reader/metrics-namespace"
  description = "Namespace that our metrics go in"
  type        = "String"
  value       = var.metrics_namespace
}

resource "aws_ssm_parameter" "parameter_memcached_location" {
  name        = "/${var.environment}/ingester-response-reader/parameter-memcached-location"
  description = "Where to find a memcached instance to cache our parameter values"
  type        = "String"
  value       = var.parameter_memcached_location
}

resource "aws_ssm_parameter" "api_server_host" {
  name        = "/${var.environment}/ingester-response-reader/api-server-host"
  description = "Host for API server"
  type        = "String"
  value       = var.api_server_host
}

resource "aws_ssm_parameter" "api_server_port" {
  name        = "/${var.environment}/ingester-response-reader/api-server-port"
  description = "Port for the API server"
  type        = "String"
  value       = var.api_server_port
}

resource "aws_ssm_parameter" "ingester_response_queue_url" {
  name        = "/${var.environment}/ingester-response-reader/ingester-response-queue-url"
  description = "Endpoint of queue we use to ingest responses about successful data ingestion"
  type        = "String"
  value       = var.ingester_response_queue_url
}

resource "aws_ssm_parameter" "ingester_response_queue_batch_size" {
  name        = "/${var.environment}/ingester-response-reader/ingester-response-queue-batchsize"
  description = "Number of items to take off of the ingester response queue in a single batch"
  type        = "String"
  value       = var.ingester_response_queue_batch_size
}

resource "aws_ssm_parameter" "ingester_response_queue_max_items_to_process" {
  name        = "/${var.environment}/ingester-response-reader/ingester-response-queue-maxitemstoprocess"
  description = "Maximum number of items to take off the ingester response queue before exiting"
  type        = "String"
  value       = var.ingester_response_queue_max_items_to_process
}

