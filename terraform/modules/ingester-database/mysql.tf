module "mysql" {
    source = "../mysql"

    environment           = "${var.environment}"
    vpc_id                = "${var.vpc_id}"
    vpc_public_subnet_ids = "${var.vpc_public_subnet_ids}"
    local_machine_cidr    = "${var.local_machine_cidr}"
    instance_type         = "${var.mysql_instance_type}"
    storage_type          = "${var.mysql_storage_type}"
    database_size_gb      = "${var.mysql_database_size_gb}"
    storage_encrypted     = "${var.mysql_storage_encrypted}"
    database_name         = "favorites"
    multi_az              = "${var.mysql_multi_az}"
    database_password     = "${var.mysql_database_password}"
    backup_retention_period_days = "${var.mysql_backup_retention_period_days}"
    init_script_file      = "ingester-database/favorites_init.sql"
}