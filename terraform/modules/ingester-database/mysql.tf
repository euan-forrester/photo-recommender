module "mysql" {
    source = "../mysql"

    environment       = "${var.environment}"
    instance_type     = "${var.mysql_instance_type}"
    storage_type      = "${var.mysql_storage_type}"
    database_size_gb  = "${var.mysql_database_size_gb}"
    database_name     = "${var.mysql_database_name}"
    multi_az          = "${var.mysql_multi_az}"
    database_password = "${var.mysql_database_password}"
}