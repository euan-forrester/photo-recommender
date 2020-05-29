resource "aws_cloudwatch_metric_alarm" "dead_letter_queue_items" {
  count = var.enable_alarms ? length(var.dead_letter_queue_names) : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "${element(var.dead_letter_queue_names, count.index)} items" # Need to have a different name for each one, or else we only see one in the UI
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = var.dead_letter_queue_items_threshold
  treat_missing_data        = "ignore" # Maintain alarm state on missing data - sometimes data will just be missing for queues for some reason
  alarm_description         = "Alerts if a dead-letter queue has items in it"
  alarm_actions             = [aws_sns_topic.alarms.arn]
  insufficient_data_actions = [aws_sns_topic.alarms.arn]
  ok_actions                = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = element(var.dead_letter_queue_names, count.index) # Taken from https://github.com/hashicorp/terraform/issues/8600
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_item_size" {
  count = var.enable_alarms ? length(var.queue_names) : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "${element(var.queue_names, count.index)} item size" # Need to have a different name for each one, or else we only see one in the UI
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "SentMessageSize"
  namespace                 = "AWS/SQS"
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = var.queue_item_size_threshold
  treat_missing_data        = "ignore" # Maintain alarm state on missing data - sometimes data will just be missing for queues for some reason
  alarm_description         = "Alerts if a queue has items that are too large"
  alarm_actions             = [aws_sns_topic.alarms.arn]
  insufficient_data_actions = [aws_sns_topic.alarms.arn]
  ok_actions                = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = element(var.queue_names, count.index) # Taken from https://github.com/hashicorp/terraform/issues/8600
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_item_age" {
  count = var.enable_alarms ? length(var.queue_names) : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "${element(var.queue_names, count.index)} item age" # Need to have a different name for each one, or else we only see one in the UI
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "ApproximateAgeOfOldestMessage"
  namespace                 = "AWS/SQS"
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = var.queue_item_age_threshold
  treat_missing_data        = "ignore" # Maintain alarm state on missing data - sometimes data will just be missing for queues for some reason
  alarm_description         = "Alerts if a queue has items that are too old. Has the process that consumes them stopped?"
  alarm_actions             = [aws_sns_topic.alarms.arn]
  insufficient_data_actions = [aws_sns_topic.alarms.arn]
  ok_actions                = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = element(var.queue_names, count.index) # Taken from https://github.com/hashicorp/terraform/issues/8600
  }
}

