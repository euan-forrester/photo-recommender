resource "aws_ssm_parameter" "metrics_namespace" {
  name        = "/${var.environment}/ingester-database/metrics-namespace"
  description = "Namespace that our metrics go in"
  type        = "String"
  value       = var.metrics_namespace
}

resource "aws_ssm_parameter" "parameter_memcached_location" {
  name        = "/${var.environment}/ingester-database/parameter-memcached-location"
  description = "Where to find a memcached instance to cache our parameter values"
  type        = "String"
  value       = var.parameter_memcached_location
}

resource "aws_ssm_parameter" "output_database_host" {
  name        = "/${var.environment}/ingester-database/output-database-host"
  description = "Host for the database into which we ingest data from the queue"
  type        = "String"
  value       = var.mysql_database_host
}

resource "aws_ssm_parameter" "output_database_port" {
  name        = "/${var.environment}/ingester-database/output-database-port"
  description = "Port for the database into which we ingest data from the queue"
  type        = "String"
  value       = var.mysql_database_port
}

resource "aws_ssm_parameter" "output_database_username" {
  name        = "/${var.environment}/ingester-database/output-database-username"
  description = "Username for the database into which we ingest data from the queue"
  type        = "String"
  value       = var.mysql_database_username
}

resource "aws_ssm_parameter" "output_database_password" {
  name        = "/${var.environment}/ingester-database/output-database-password"
  description = "Password for the database into which we ingest data from the queue"
  type        = "SecureString"
  key_id      = var.kms_key_id
  value       = var.mysql_database_password
}

resource "aws_ssm_parameter" "output_database_name" {
  name        = "/${var.environment}/ingester-database/output-database-name"
  description = "Name for the database into which we ingest data from the queue"
  type        = "String"
  value       = var.mysql_database_name
}

resource "aws_ssm_parameter" "output_database_min_batch_size" {
  name        = "/${var.environment}/ingester-database/output-database-min-batchsize"
  description = "Minimum number of items to put into the database in a single batch"
  type        = "String"
  value       = var.mysql_database_min_batch_size
}

resource "aws_ssm_parameter" "output_database_maxretries" {
  name        = "/${var.environment}/ingester-database/output-database-maxretries"
  description = "Number of items to retry a put operation to the database"
  type        = "String"
  value       = var.mysql_database_maxretries
}

resource "aws_ssm_parameter" "input_queue_url" {
  name        = "/${var.environment}/ingester-database/input-queue-url"
  description = "Endpoint of queue we use to ingest favorites data intended for the database"
  type        = "String"
  value       = module.input_sqs_queue.queue_url
}

resource "aws_ssm_parameter" "input_queue_batch_size" {
  name        = "/${var.environment}/ingester-database/input-queue-batchsize"
  description = "Number of items to take off of the input queue in a single batch"
  type        = "String"
  value       = var.input_queue_batch_size
}

resource "aws_ssm_parameter" "input_queue_max_items_to_process" {
  name        = "/${var.environment}/ingester-database/input-queue-maxitemstoprocess"
  description = "Maximum number of items to take off the input queue before exiting"
  type        = "String"
  value       = var.input_queue_max_items_to_process
}

resource "aws_ssm_parameter" "output_queue_url" {
  name        = "/${var.environment}/ingester-database/output-queue-url"
  description = "URL of the queue to put ingester response messages on"
  type        = "String"
  value       = module.output_sqs_queue.queue_url
}

resource "aws_ssm_parameter" "output_queue_batch_size" {
  name        = "/${var.environment}/ingester-database/output-queue-batchsize"
  description = "Number of items to put on the output queue in a single batch"
  type        = "String"
  value       = var.output_queue_batch_size
}

