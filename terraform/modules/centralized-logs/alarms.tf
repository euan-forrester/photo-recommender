# Copied from the AWS centralized logging template: https://docs.aws.amazon.com/solutions/latest/centralized-logging/templates.html

resource "aws_cloudwatch_metric_alarm" "status_yellow_alarm" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} cluster status yellow"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ClusterStatus.yellow"
  namespace                 = "AWS/ES"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = 1
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Replica shards for at least one index are not allocated to nodes in a cluster."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "status_red_alarm" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} cluster status red"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ClusterStatus.red"
  namespace                 = "AWS/ES"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = 1
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Primary and replica shards of at least one index are not allocated to nodes in a cluster."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} cpu utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 3
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ES"
  period                    = 900
  statistic                 = "Average"
  threshold                 = 80
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Average CPU utilization over last 45 minutes too high."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "master_cpu_utilization_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} master cpu utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 3
  metric_name               = "MasterCPUUtilization"
  namespace                 = "AWS/ES"
  period                    = 900
  statistic                 = "Average"
  threshold                 = 50
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Average CPU utilization on master over last 45 minutes too high."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space_too_low_alarm" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} free storage space too low"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "FreeStorageSpace"
  namespace                 = "AWS/ES"
  period                    = 60
  statistic                 = "Minimum"
  threshold                 = 2000
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Cluster has less than 2GB of storage space."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "index_write_blocked_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} index write blocked"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ClusterIndexWritesBlocked"
  namespace                 = "AWS/ES"
  period                    = 300
  statistic                 = "Maximum"
  threshold                 = 1
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Cluster is blocking incoming write requests."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}

resource "aws_cloudwatch_metric_alarm" "jvm_memory_pressure_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} jvm memory pressure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "JVMMemoryPressure"
  namespace                 = "AWS/ES"
  period                    = 900
  statistic                 = "Average"
  threshold                 = 80
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Average JVM memory pressure over last 15 minutes too high."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
}  

resource "aws_cloudwatch_metric_alarm" "master_jvm_memory_pressure_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} master jvm memory pressure"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "MasterJVMMemoryPressure"
  namespace                 = "AWS/ES"
  period                    = 900
  statistic                 = "Average"
  threshold                 = 50
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Average master JVM memory pressure over last 15 minutes too high."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
} 

resource "aws_cloudwatch_metric_alarm" "master_not_reachable_from_node" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} master node not reachable"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 1
  metric_name               = "MasterReachableFromNode"
  namespace                 = "AWS/ES"
  period                    = 60
  statistic                 = "Minimum"
  threshold                 = 1
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: Master node stopped or not reachable. Usually the result of a network connectivity issue or AWS dependency problem."
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
} 

resource "aws_cloudwatch_metric_alarm" "automated_snapshot_failure_too_high" {
  count = var.enable_alarms && var.centralized_logs_enabled ? 1 : 0 # Don't create this if we turn off alarms (e.g. for dev)

  alarm_name                = "Centralized Logging ${var.environment} automated snapshot failure too high"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "AutomatedSnapshotFailure"
  namespace                 = "AWS/ES"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = 1
  treat_missing_data        = "ignore" # Maintain alarm state on missing data
  alarm_description         = "Centralized Logging ${var.environment}: No automated snapshot was taken for the domain in the previous 36 hours"
  alarm_actions             = [var.alarms_sns_topic_arn]
  insufficient_data_actions = [var.alarms_sns_topic_arn]
  ok_actions                = [var.alarms_sns_topic_arn]

  dimensions = {
    ClientId = data.aws_caller_identity.centralized_logs.account_id
    DomainName = var.elastic_search_domain_name
  }
} 
