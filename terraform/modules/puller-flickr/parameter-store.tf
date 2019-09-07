resource "aws_kms_key" "parameter_secrets" {
    description             = "Used to encrypt/decrypt puller-flickr secrets in the Parameter Store"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_ssm_parameter" "metrics_namespace" {
    name        = "/${var.environment}/puller-flickr/metrics-namespace"
    description = "Namespace that our metrics go in"
    type        = "String"
    value       = "${var.metrics_namespace}"
}

resource "aws_ssm_parameter" "parameter_memcached_location" {
    name        = "/${var.environment}/puller-flickr/parameter-memcached-location"
    description = "Where to find a memcached instance to cache our parameter values"
    type        = "String"
    value       = "${var.parameter_memcached_location}"
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

resource "aws_ssm_parameter" "flickr_api_contacts_max_per_call" {
    name        = "/${var.environment}/puller-flickr/flickr-api-contacts-maxpercall"
    description = "Max number of contacts to get per API call"
    type        = "String"
    value       = "${var.flickr_api_contacts_max_per_call}"
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

resource "aws_ssm_parameter" "flickr_api_favorites_max_calls_to_make" {
    name        = "/${var.environment}/puller-flickr/flickr-api-favorites-maxcallstomake"
    description = "Max number of calls to favorites endpoint to make per user."
    type        = "String"
    value       = "${var.flickr_api_favorites_max_calls_to_make}"
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
    value       = "${var.memcached_location}"
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

resource "aws_ssm_parameter" "puller_queue_url" {
    name        = "/${var.environment}/puller-flickr/puller-queue-url"
    description = "URL of the queue to get requests for data to be pulled"
    type        = "String"
    value       = "${var.puller_queue_url}"
}

resource "aws_ssm_parameter" "puller_queue_batch_size" {
    name        = "/${var.environment}/puller-flickr/puller-queue-batchsize"
    description = "Number of items to get from the puller queue in a single batch"
    type        = "String"
    value       = "${var.puller_queue_batch_size}"
}

resource "aws_ssm_parameter" "puller_queue_max_items_to_process" {
    name        = "/${var.environment}/puller-flickr/puller-queue-maxitemstoprocess"
    description = "Maximum number of items to get from the puller queue before exiting"
    type        = "String"
    value       = "${var.puller_queue_max_items_to_process}"
}

resource "aws_ssm_parameter" "puller_response_queue_url" {
    name        = "/${var.environment}/puller-flickr/puller-response-queue-url"
    description = "URL where we put messages saying we've successfully pulled data"
    type        = "String"
    value       = "${var.puller_response_queue_url}"
}
