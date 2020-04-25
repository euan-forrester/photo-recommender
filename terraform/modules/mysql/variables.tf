variable "environment" {}
variable "instance_type" {}
variable "database_size_gb" {}
variable "database_name" {}
variable "multi_az" {}
variable "storage_type" {}
variable "database_password" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }
variable "local_machine_cidr" {}
variable "vpc_cidr" {}
variable "backup_retention_period_days" {}
variable "init_script_file" {}
variable "storage_encrypted" {}
variable "deletion_protection" {}
variable "kms_key_arn" {}