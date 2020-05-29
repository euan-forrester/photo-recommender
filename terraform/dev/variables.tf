variable "region" {
  default = "us-west-2"
}

variable "environment" {
  default = "dev"
}

variable "environment_long_name" {
  default = "development"
}

variable "alarms_email" {
}

variable "application_name" {
  default = "photo-recommender"
}

variable "application_name_no_hyphens" {
  default = "photorecommender"
}

variable "metrics_namespace" {
  default = "Photo Recommender"
}

variable "local_machine_cidr" {
}

variable "local_machine_public_key" {
}

variable "flickr_api_key" {
}

variable "flickr_secret_key" {
}

variable "database_password_dev" {
}

variable "database_password_prod" {
}

variable "dns_address" {
}

variable "bucketname_user_string" {
}

variable "database_user_data_encryption_key_dev" {
}

variable "api_server_session_encryption_key_dev" {
}

variable "database_user_data_encryption_key_prod" {
}

variable "api_server_session_encryption_key_prod" {
}

variable "ssl_certificate_body" {
}

variable "ssl_certificate_private_key" {
}

variable "ssl_certificate_chain" {
}

variable "project_github_location" {
}

