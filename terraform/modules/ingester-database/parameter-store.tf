resource "aws_ssm_parameter" "queue_url" {
    name        = "/${var.environment}/ingester-database/ingestion-queue-url"
    description = "Endpoint of queue we use to ingest favorites data intended for the database"
    type        = "String"
    value       = "${module.sqs_queue.queue_url}"
}