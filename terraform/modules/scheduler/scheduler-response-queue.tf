module "scheduler_response_queue" {
    source = "../sqs-queue"

    queue_name                  = "scheduler-response-queue"
    environment                 = "${var.environment}"
    max_redrives                = 4
    visibility_timeout_seconds  = 30
    message_retention_seconds   = 1209600 # 14 days
}