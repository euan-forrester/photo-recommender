resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt api-server secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "parameter_memcached_location" {
    name        = "/${var.environment}/api-server/parameter-memcached-location"
    description = "Where to find a memcached instance to cache our parameter values"
    type        = "String"
    value       = "${var.parameter_memcached_location}"
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

resource "aws_ssm_parameter" "database_fetch_batch_size" {
    name        = "/${var.environment}/api-server/database-fetch-batch-size"
    description = "Number of records to read from the database per batch"
    type        = "String"
    value       = "${var.mysql_database_fetch_batch_size}"
}

resource "aws_ssm_parameter" "database_connection_pool_size" {
    name        = "/${var.environment}/api-server/database-connection-pool-size"
    description = "Size of our pool of connections to the database"
    type        = "String"
    value       = "${var.mysql_database_connection_pool_size}"
}

resource "aws_ssm_parameter" "api_server_host" {
    name        = "/${var.environment}/api-server/server-host"
    description = "Host we listen on to serve requests"
    type        = "String"
    value       = "0.0.0.0"
}

resource "aws_ssm_parameter" "api_server_port" {
    name        = "/${var.environment}/api-server/server-port"
    description = "Port we listen on to serve requests"
    type        = "String"
    value       = "${var.api_server_port}"
}

resource "aws_ssm_parameter" "default_num_photo_recommendations" {
    name        = "/${var.environment}/api-server/default-num-photo-recommendations"
    description = "Number of photo recommendations we return if the caller doesn't specify"
    type        = "String"
    value       = "${var.default_num_photo_recommendations}"
}
