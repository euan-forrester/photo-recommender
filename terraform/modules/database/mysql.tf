module "mysql" {
    source = "../mysql"

    environment           = "${var.environment}"
    vpc_id                = "${var.vpc_id}"
    vpc_public_subnet_ids = "${var.vpc_public_subnet_ids}"
    local_machine_cidr    = "${var.local_machine_cidr}"
    vpc_cidr              = "${var.vpc_cidr}"
    instance_type         = "${var.mysql_instance_type}"
    storage_type          = "${var.mysql_storage_type}"
    database_size_gb      = "${var.mysql_database_size_gb}"
    storage_encrypted     = "${var.mysql_storage_encrypted}"
    database_name         = "${var.mysql_database_name}"
    multi_az              = "${var.mysql_multi_az}"
    database_password     = "${var.mysql_database_password}"
    backup_retention_period_days = "${var.mysql_backup_retention_period_days}"
    deletion_protection   = "${var.mysql_deletion_protection}"
    init_script_file      = "database/photo_recommender_init.sql"
}