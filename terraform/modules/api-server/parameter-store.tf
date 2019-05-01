resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt api-server secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "database_host" {
    name        = "/${var.environment}/api-server/database-host"
    description = "Host for the database from which we read our data"
    type        = "String"
    value       = "${var.mysql_database_host}"
}

resource "aws_ssm_parameter" "database_port" {
    name        = "/${var.environment}/api-server/database-port"
    description = "Port for the database from which we read our data"
    type        = "String"
    value       = "${var.mysql_database_port}"
}

resource "aws_ssm_parameter" "database_username" {
    name        = "/${var.environment}/api-server/database-username"
    description = "Username for the database from which we read our data"
    type        = "String"
    value       = "${var.mysql_database_username}"
}

resource "aws_ssm_parameter" "database_password" {
    name        = "/${var.environment}/api-server/database-password"
    description = "Password for the database from which we read our data"
    type        = "SecureString"
    key_id      = "${aws_kms_key.parameter_secrets.id}"
    value       = "${var.mysql_database_password}"
}

resource "aws_ssm_parameter" "database_name" {
    name        = "/${var.environment}/api-server/database-name"
    description = "Name for the database from which we read our data"
    type        = "String"
    value       = "${var.mysql_database_name}"
}

resource "aws_ssm_parameter" "api_server_port" {
    name        = "/${var.environment}/api-server/server-port"
    description = "Port we listen on to serve requests"
    type        = "String"
    value       = "${var.api_server_port}"
}

