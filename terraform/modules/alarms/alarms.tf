resource "aws_cloudwatch_metric_alarm" "unhandled_exceptions" {
    count                     = "${var.enable_alarms == "true" ? length(var.process_names) : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "Unhandled exceptions in ${element(var.process_names, count.index)}" # Need to have a different name for each one, or else we only see one in the UI
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "UnhandledException"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.unhandled_exceptions_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if a process encounters unhandled exceptions"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "${element(var.process_names, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
    }
}

resource "aws_cloudwatch_metric_alarm" "users_store_exception" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "Scheduler encountered UsersStoreException"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "UsersStoreException"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.scheduler_users_store_exception_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if the Scheduler is unable to talk to the API server"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "scheduler"
    }
}

resource "aws_cloudwatch_metric_alarm" "favorites_store_exception" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "API server encountered FavoritesStoreException"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "FavoritesStoreException"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.api_server_favorites_store_exception_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if the API server is unable to talk to the database"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "api-server"
    }
}

resource "aws_cloudwatch_metric_alarm" "api_server_exception" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "API server encountered a generic Exception"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "Exception"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.api_server_generic_exception_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if the API server encounters a generic Exception"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "api-server"
    }
}

resource "aws_cloudwatch_metric_alarm" "dead_letter_queue_items" {
    count                     = "${var.enable_alarms == "true" ? length(var.dead_letter_queue_names) : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "${element(var.dead_letter_queue_names, count.index)} items" # Need to have a different name for each one, or else we only see one in the UI
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "ApproximateNumberOfMessagesVisible"
    namespace                 = "AWS/SQS"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.dead_letter_queue_items_threshold}"
    treat_missing_data        = "ignore" # Maintain alarm state on missing data - sometimes data will just be missing for queues for some reason
    alarm_description         = "Alerts if a dead-letter queue has items in it"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        QueueName   = "${element(var.dead_letter_queue_names, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
    }
}

resource "aws_cloudwatch_metric_alarm" "queue_item_size" {
    count                     = "${var.enable_alarms == "true" ? length(var.queue_names) : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "${element(var.queue_names, count.index)} item size" # Need to have a different name for each one, or else we only see one in the UI
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "SentMessageSize"
    namespace                 = "AWS/SQS"
    period                    = "300"
    statistic                 = "Maximum"
    threshold                 = "${var.queue_item_size_threshold}"
    treat_missing_data        = "ignore" # Maintain alarm state on missing data - sometimes data will just be missing for queues for some reason
    alarm_description         = "Alerts if a queue has items that are too large"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        QueueName   = "${element(var.queue_names, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
    }
}