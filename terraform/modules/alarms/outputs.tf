output "sns_topic_arn" {
  value       = aws_sns_topic.alarms.arn
  description = "ARN of the SNS topic that was created"
}

output "enable_alarms" {
  value       = var.enable_alarms
  description = "Whether alarms are enabled or not"
}