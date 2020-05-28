output "kms_key_id" {
  value       = aws_kms_key.parameter_secrets.id
  description = "The ID of the key used to encrypt/decrypt secrets in the Parameter Store and elsewhere"
}

output "kms_key_arn" {
  value       = aws_kms_key.parameter_secrets.arn
  description = "The ARN of the key used to encrypt/decrypt secrets in the Parameter Store and elsewhere"
}

