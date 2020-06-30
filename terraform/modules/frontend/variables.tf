variable "environment" {
}

variable "environment_long_name" {
}

variable "region" {
}

variable "days_to_keep_old_versions" {
}

variable "load_balancer_dns_name" {
}

variable "load_balancer_port" {
}

variable "load_balancer_zone_id" {
}

variable "load_balancer_arn" {
}

variable "application_name" {
}

variable "application_domain" {
}

variable "frontend_access_logs_bucket" {
}

variable "retain_frontend_access_logs_after_destroy" {
  type = bool
}

variable "days_to_keep_frontend_access_logs" {
}

variable "bucketname_user_string" {
}

variable "use_custom_domain" {
  type = bool
}

variable "project_github_location" {
}

variable "build_logs_bucket_id" {
}

variable "buildspec_location" {
}

variable "file_path" {
}

variable "build_service_role_arn" {
}

