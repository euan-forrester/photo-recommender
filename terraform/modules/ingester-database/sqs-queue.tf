module "sqs_queue" {
    source = "../sqs-queue"

    queue_name                  = "ingester-queue"
    environment                 = "${var.environment}"
    max_redrives                = 4
    visibility_timeout_seconds  = 30
    message_retention_seconds   = 7200
}