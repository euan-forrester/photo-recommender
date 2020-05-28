output "database_host" {
  value       = element(split(":", aws_db_instance.mysql_database.endpoint), 0)
  description = "The host of the database that was created"
}

output "database_port" {
  value       = aws_db_instance.mysql_database.port
  description = "The port of the database that was created"
}

output "database_username" {
  value       = aws_db_instance.mysql_database.username
  description = "The username for the database that was created"
}

output "database_name" {
  value       = aws_db_instance.mysql_database.name
  description = "The name of the database that was created within the instance"
}

output "database_instance_identifier" {
  value       = aws_db_instance.mysql_database.identifier
  description = "The identifier of the database instance that was created"
}

