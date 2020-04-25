resource "aws_ssm_parameter" "metrics_namespace" {
    name        = "/${var.environment}/api-server/metrics-namespace"
    description = "Namespace that our metrics go in"
    type        = "String"
    value       = "${var.metrics_namespace}"
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
    key_id      = "${var.kms_key_id}"
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

resource "aws_ssm_parameter" "database_user_data_encryption_key" {
    name        = "/${var.environment}/api-server/database-user-data-encryption-key"
    description = "256-bit AES encryption key used to encrypt user access tokens stored in the database"
    type        = "SecureString"
    key_id      = "${var.kms_key_id}"
    value       = "${var.mysql_database_user_data_encryption_key}"
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

resource "aws_ssm_parameter" "session_encryption_key" {
    name        = "/${var.environment}/api-server/session-encryption-key"
    description = "Encryption key used to sign the session data we return to the user"
    type        = "SecureString"
    key_id      = "${var.kms_key_id}"
    value       = "${var.session_encryption_key}"
}

resource "aws_ssm_parameter" "flickr_api_key" {
    name        = "/${var.environment}/api-server/flickr-api-key"
    description = "Flickr API key"
    type        = "String"
    value       = "${var.flickr_api_key}"
}

resource "aws_ssm_parameter" "flickr_secret_key" {
    name        = "/${var.environment}/api-server/flickr-api-secret"
    description = "Flickr API secret key"
    type        = "SecureString"
    key_id      = "${var.kms_key_id}"
    value       = "${var.flickr_secret_key}"
}

resource "aws_ssm_parameter" "flickr_api_retries" {
    name        = "/${var.environment}/api-server/flickr-api-retries"
    description = "Max number of times to retry a Flickr API call"
    type        = "String"
    value       = "${var.flickr_api_retries}"
}

resource "aws_ssm_parameter" "flickr_api_memcached_ttl" {
    name        = "/${var.environment}/api-server/flickr-api-memcached-ttl"
    description = "TTL in seconds of Flickr API calls put into memcached"
    type        = "String"
    value       = "${var.flickr_api_memcached_ttl}"
}

resource "aws_ssm_parameter" "flickr_api_memcached_location" {
    name        = "/${var.environment}/api-server/flickr-api-memcached-location"
    description = "Endpoint of the memcached cluster that we cache Flickr API calls to"
    type        = "String"
    value       = "${var.flickr_api_memcached_location}"
}

resource "aws_ssm_parameter" "flickr_auth_memcached_location" {
    name        = "/${var.environment}/api-server/flickr-auth-memcached-location"
    description = "Endpoint of the memcached cluster that we cache temporary Flickr auth request tokens in"
    type        = "String"
    value       = "${var.flickr_auth_memcached_location}"
}

resource "aws_ssm_parameter" "flickr_auth_cache_type" {
    name        = "/${var.environment}/api-server/flickr-auth-cache-type"
    description = "Type of cache that we use to store temporary Flickr auth request tokens in"
    type        = "String"
    value       = "memcached"
}

resource "aws_ssm_parameter" "default_num_photo_recommendations" {
    name        = "/${var.environment}/api-server/default-num-photo-recommendations"
    description = "Number of photo recommendations we return if the caller doesn't specify"
    type        = "String"
    value       = "${var.default_num_photo_recommendations}"
}

resource "aws_ssm_parameter" "default_num_user_recommendations" {
    name        = "/${var.environment}/api-server/default-num-user-recommendations"
    description = "Number of user recommendations we return if the caller doesn't specify"
    type        = "String"
    value       = "${var.default_num_user_recommendations}"
}

resource "aws_ssm_parameter" "default_num_photos_from_group" {
    name        = "/${var.environment}/api-server/default-num-photos-from-group"
    description = "Number of photos from a group we return if the caller doesn't specify"
    type        = "String"
    value       = "${var.default_num_photos_from_group}"
}

resource "aws_ssm_parameter" "puller_queue_url" {
    name        = "/${var.environment}/api-server/puller-queue-url"
    description = "URL of the queue to put requests for data to be pulled"
    type        = "String"
    value       = "${var.puller_queue_url}"
}

resource "aws_ssm_parameter" "puller_queue_batch_size" {
    name        = "/${var.environment}/api-server/puller-queue-batchsize"
    description = "Number of items to put on the puller queue in a single batch"
    type        = "String"
    value       = "${var.puller_queue_batch_size}"
}
