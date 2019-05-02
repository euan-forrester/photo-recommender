resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt puller-flickr secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "flickr_user_id" {
    name        = "/${var.environment}/puller-flickr/flickr-user-id"
    description = "Numerical user ID of the user for whom we're recommending photos"
    type        = "String"
    value       = "${var.flickr_user_id}"
}

resource "aws_ssm_parameter" "flickr_api_key" {
    name        = "/${var.environment}/puller-flickr/flickr-api-key"
    description = "Flickr API key"
    type        = "String"
    value       = "${var.flickr_api_key}"
}

resource "aws_ssm_parameter" "flickr_secret_key" {
    name        = "/${var.environment}/puller-flickr/flickr-api-secret"
    description = "Flickr API secret key"
    type        = "SecureString"
    key_id      = "${aws_kms_key.parameter_secrets.id}"
    value       = "${var.flickr_secret_key}"
}

resource "aws_ssm_parameter" "flickr_api_retries" {
    name        = "/${var.environment}/puller-flickr/flickr-api-retries"
    description = "Max number of times to retry a Flickr API call"
    type        = "String"
    value       = "${var.flickr_api_retries}"
}

resource "aws_ssm_parameter" "flickr_api_favorites_max_per_call" {
    name        = "/${var.environment}/puller-flickr/flickr-api-favorites-maxpercall"
    description = "Max number of favorites to get per API call"
    type        = "String"
    value       = "${var.flickr_api_favorites_max_per_call}"
}

resource "aws_ssm_parameter" "flickr_api_favorites_max_to_get" {
    name        = "/${var.environment}/puller-flickr/flickr-api-favorites-maxtoget"
    description = "Max number of favorites to get in total"
    type        = "String"
    value       = "${var.flickr_api_favorites_max_to_get}"
}

resource "aws_ssm_parameter" "memcached_ttl" {
    name        = "/${var.environment}/puller-flickr/memcached-ttl"
    description = "TTL in seconds of Flickr API calls put into memcached"
    type        = "String"
    value       = "${var.memcached_ttl}"
}

resource "aws_ssm_parameter" "memcached_location" {
    name        = "/${var.environment}/puller-flickr/memcached-location"
    description = "Endpoint of the memcached cluster that we cache Flickr API calls to"
    type        = "String"
    value       = "${var.memcached_num_cache_nodes != 0 ? format("%s:%d", aws_elasticache_cluster.memcached.cluster_address, aws_elasticache_cluster.memcached.port) : "localhost:11211"}" # If we specifed having no nodes, then then there's no cluster and just try to connect to localhost. See https://itnext.io/things-i-wish-i-knew-about-terraform-before-jumping-into-it-43ee92a9dd65
}

resource "aws_ssm_parameter" "output_queue_url" {
    name        = "/${var.environment}/puller-flickr/output-queue-url"
    description = "URL of the queue to put favorites data into for later ingestion into the database"
    type        = "String"
    value       = "${var.output_queue_url}"
}

resource "aws_ssm_parameter" "output_queue_batch_size" {
    name        = "/${var.environment}/puller-flickr/output-queue-batchsize"
    description = "Number of items to put on the output queue in a single batch"
    type        = "String"
    value       = "${var.output_queue_batch_size}"
}