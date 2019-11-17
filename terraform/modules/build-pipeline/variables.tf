variable "environment" {}
variable "region" {}
variable "project_github_location" {}
variable "vpc_id" {}        
variable "vpc_subnet_ids" { type = "list" }
variable "local_machine_cidr" {}
variable "build_logs_bucket" {}
variable "bucketname_user_string" {}
variable "retain_build_logs_after_destroy" {}
variable "days_to_keep_build_logs" {}