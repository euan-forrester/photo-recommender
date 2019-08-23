module "puller_queue" {
    source = "../sqs-queue"

    queue_name                  = "puller-queue"
    environment                 = "${var.environment}"
    max_redrives                = 4
    visibility_timeout_seconds  = 900 # 15 minutes. It can take quite a while to pull all of the favorites for a user if they have a lot 
    message_retention_seconds   = 1209600 # 14 days
}