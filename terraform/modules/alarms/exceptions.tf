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

resource "aws_cloudwatch_metric_alarm" "queue_reader_error" {
    count                     = "${var.enable_alarms == "true" ? length(var.process_names_that_read_from_queues) : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "QueueReaderError in ${element(var.process_names_that_read_from_queues, count.index)}" # Need to have a different name for each one, or else we only see one in the UI
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "QueueReaderError"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.queue_reader_error_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if a process encounters an error reading from a queue"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "${element(var.process_names_that_read_from_queues, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
    }
}

resource "aws_cloudwatch_metric_alarm" "queue_writer_error" {
    count                     = "${var.enable_alarms == "true" ? length(var.process_names_that_write_to_queues) : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "QueueWriterError in ${element(var.process_names_that_write_to_queues, count.index)}" # Need to have a different name for each one, or else we only see one in the UI
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "QueueWriterError"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.queue_writer_error_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if a process encounters an error writing to a queue"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "${element(var.process_names_that_write_to_queues, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
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

resource "aws_cloudwatch_metric_alarm" "database_batch_writer_exception" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "ingester-database encountered a DatabaseBatchWriterException"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "DatabaseBatchWriterException"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.ingester_database_batch_writer_exception_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if ingester-database encounters an error writing to the database"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "ingester-database"
    }
}

resource "aws_cloudwatch_metric_alarm" "puller_flickr_max_batch_size_exceeded" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "puller-flickr encountered a MaxBatchSizeExceeded error"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "MaxBatchSizeExceeded"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.puller_flickr_max_batch_size_exceeded_error_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if puller-flickr tries to write too many favorite photos in a single batch"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "puller-flickr"
    }
}

resource "aws_cloudwatch_metric_alarm" "puller_flickr_max_neighbors_exceeded" {
    count                     = "${var.enable_alarms == "true" ? 1 : 0}" # Don't create this if we turn off alarms (e.g. for dev)

    alarm_name                = "puller-flickr encountered a MaxNeighborsExceeded error"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = "1"
    metric_name               = "MaxNeighborsExceeded"
    namespace                 = "${var.metrics_namespace}"
    period                    = "300"
    statistic                 = "Sum"
    threshold                 = "${var.puller_flickr_max_neighbors_exceeded_error_threshold}"
    treat_missing_data        = "notBreaching" # No news is good news for exceptions
    alarm_description         = "Alerts if puller-flickr tries to write too many neighbors to a single scheduler response item"
    alarm_actions             = [ "${aws_sns_topic.alarms.arn}" ]
    insufficient_data_actions = [ "${aws_sns_topic.alarms.arn}" ]
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "puller-flickr"
    }
}