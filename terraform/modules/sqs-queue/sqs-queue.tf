resource "aws_sqs_queue" "queue" {
    name                        = "${var.queue_name}-${var.environment}"
    visibility_timeout_seconds  = "${var.visibility_timeout_seconds}"
    delay_seconds               = 0
    max_message_size            = 262144 # 256kB
    message_retention_seconds   = "${var.message_retention_seconds}"
    receive_wait_time_seconds   = 10 # Enable long polling: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html#sqs-long-polling
    redrive_policy              = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dead_letter_queue.arn}\",\"maxReceiveCount\":${var.max_redrives}}"

    tags = {
        Environment = "${var.environment}"
    }

    # Not sure why we need an explicit dependency here, but otherwise we get an error saying that the queue referenced
    # in the redrive policy doesn't exist yet.
    depends_on = [
        "aws_sqs_queue.dead_letter_queue"
    ]
}

resource "aws_sqs_queue" "dead_letter_queue" {
    name                      = "${var.queue_name}-dead-letter-${var.environment}"
    delay_seconds             = 0
    max_message_size          = 262144 # 256kB
    message_retention_seconds = 1209600 # 14 days
    receive_wait_time_seconds = 0

    tags = {
        Environment = "${var.environment}"
    }
}