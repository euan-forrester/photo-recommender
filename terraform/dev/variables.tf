variable "region" { default = "us-west-2" }
variable "environment" { default = "dev" }
variable "alarms_email" {}
variable "metrics_namespace" { default = "Photo Recommender" }
variable "local_machine_cidr" {}
variable "local_machine_public_key" {}
variable "flickr_api_key" {}
variable "flickr_secret_key" {}
variable "database_password_dev" {}
variable "dns_address" {}
variable "bucketname_user_string" {}
variable "database_user_data_encryption_key_dev" {}
variable "api_server_session_encryption_key_dev" {}
variable "ssl_certificate_body" {}
variable "ssl_certificate_private_key" {}
variable "ssl_certificate_chain" {}
variable "project_github_location" {}