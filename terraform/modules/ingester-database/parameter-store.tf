resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt ingester-database secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "database_endpoint" {
    name        = "/${var.environment}/ingester-database/database-endpoint"
    description = "Endpoint of the database into which we ingest data from the queue"
    type        = "String"
    value       = "${module.mysql.database_endpoint}"
}

resource "aws_ssm_parameter" "input_queue_url" {
    name        = "/${var.environment}/ingester-database/input-queue-url"
    description = "Endpoint of queue we use to ingest favorites data intended for the database"
    type        = "String"
    value       = "${module.sqs_queue.queue_url}"
}

resource "aws_ssm_parameter" "input_queue_batch_size" {
    name        = "/${var.environment}/ingester-database/input-queue-batchsize"
    description = "Number of items to take off of the input queue in a single batch"
    type        = "String"
    value       = "${var.input_queue_batch_size}"
}

resource "aws_ssm_parameter" "input_queue_max_items_to_process" {
    name        = "/${var.environment}/ingester-database/input-queue-maxitemstoprocess"
    description = "Maximum number of items to take off the input queue before exiting"
    type        = "String"
    value       = "${var.input_queue_max_items_to_process}"
}