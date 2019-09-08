module "puller_queue" {
    source = "../sqs-queue"

    queue_name                  = "puller-queue"
    environment                 = "${var.environment}"
    max_redrives                = 4
    visibility_timeout_seconds  = 45 # It can take quite a while to pull all of the favorites for a user if they have a lot 
    message_retention_seconds   = 1209600 # 14 days
    long_polling_seconds        = "${var.puller_queue_long_polling_seconds}"
}