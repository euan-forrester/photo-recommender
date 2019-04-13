resource "aws_ssm_parameter" "queue_url" {
    name        = "/${var.environment}/ingester-database/ingestion-queue-url"
    description = "Endpoint of queue we use to ingest favorites data intended for the database"
    type        = "String"
    value       = "${module.sqs_queue.queue_url}"
}

resource "aws_ssm_parameter" "database_endpoint" {
    name        = "/${var.environment}/ingester-database/database-endpoint"
    description = "Endpoint of the database into which we ingest data from the queue"
    type        = "String"
    value       = "${module.mysql.database_endpoint}"
}