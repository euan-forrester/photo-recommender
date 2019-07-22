resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt ingester-database secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "output_database_host" {
    name        = "/${var.environment}/ingester-database/output-database-host"
    description = "Host for the database into which we ingest data from the queue"
    type        = "String"
    value       = "${var.mysql_database_host}"
}

resource "aws_ssm_parameter" "output_database_port" {
    name        = "/${var.environment}/ingester-database/output-database-port"
    description = "Port for the database into which we ingest data from the queue"
    type        = "String"
    value       = "${var.mysql_database_port}"
}

resource "aws_ssm_parameter" "output_database_username" {
    name        = "/${var.environment}/ingester-database/output-database-username"
    description = "Username for the database into which we ingest data from the queue"
    type        = "String"
    value       = "${var.mysql_database_username}"
}

resource "aws_ssm_parameter" "output_database_password" {
    name        = "/${var.environment}/ingester-database/output-database-password"
    description = "Password for the database into which we ingest data from the queue"
    type        = "SecureString"
    key_id      = "${aws_kms_key.parameter_secrets.id}"
    value       = "${var.mysql_database_password}"
}

resource "aws_ssm_parameter" "output_database_name" {
    name        = "/${var.environment}/ingester-database/output-database-name"
    description = "Name for the database into which we ingest data from the queue"
    type        = "String"
    value       = "${var.mysql_database_name}"
}

resource "aws_ssm_parameter" "output_database_batch_size" {
    name        = "/${var.environment}/ingester-database/output-database-batchsize"
    description = "Number of items to put into the database in a single batch"
    type        = "String"
    value       = "${var.mysql_database_batch_size}"
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
