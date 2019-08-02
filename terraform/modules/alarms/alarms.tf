resource "aws_cloudwatch_metric_alarm" "unhandled_exceptions" {
    count                     = "${var.unhandled_exceptions_threshold > 0 ? length(var.process_names) : 0}" # Don't create this if we specify a 0 or negative threshold (e.g. for dev)

    alarm_name                = "Unhandled exceptions ${element(var.process_names, count.index)}" # Need to have a different name for each one, or else we only see one in the UI
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
    ok_actions                = [ "${aws_sns_topic.alarms.arn}" ]

    dimensions {
        Environment = "${var.environment}"
        Process     = "${element(var.process_names, count.index)}" # Taken from https://github.com/hashicorp/terraform/issues/8600
    }
}