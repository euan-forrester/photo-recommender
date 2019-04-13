resource "aws_kms_key" "mysql_encryption" {
    description             = "Used to encrypt the contents of the ${var.database_name}-${var.environment} mysql database"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_db_instance" "mysql_database" {

    instance_class                  = "${var.instance_type}"
    identifier                      = "${var.database_name}-${var.environment}"
    name                            = "${var.database_name}"
    multi_az                        = "${var.multi_az}"

    allocated_storage               = "${var.database_size_gb}"
    storage_type                    = "${var.storage_type}"

    storage_encrypted               = true
    kms_key_id                      = "${aws_kms_key.mysql_encryption.arn}"

    engine                          = "mysql"
    engine_version                  = "8.0"
    parameter_group_name            = "default.mysql8.0"

    allow_major_version_upgrade     = false
    apply_immediately               = true
    auto_minor_version_upgrade      = true
    backup_retention_period         = 7
    copy_tags_to_snapshot           = true
    deletion_protection             = false

    enabled_cloudwatch_logs_exports = [ "error", "general", "slowquery" ]
    monitoring_interval             = 0

    iam_database_authentication_enabled = false
    username                        = "${var.database_name}_${var.environment}"
    password                        = "${var.database_password}"

    publicly_accessible             = false

    tags = {
        Environment = "${var.environment}"
    }
}           
