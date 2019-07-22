variable "environment" {}
variable "region" {}
variable "mysql_database_name" {}
variable "mysql_instance_type" {}
variable "mysql_database_size_gb" {}
variable "mysql_storage_type" {}
variable "mysql_multi_az" {}
variable "mysql_database_password" {}
variable "mysql_backup_retention_period_days" {}
variable "mysql_storage_encrypted" {}
variable "vpc_id" {}
variable "vpc_public_subnet_ids" { type = "list" }
variable "local_machine_cidr" {}
variable "vpc_cidr" {}