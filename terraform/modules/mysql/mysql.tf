resource "aws_db_subnet_group" "public_subnet_group" {
  name       = "db-subnet-group-${var.database_name}-${var.environment}"
  subnet_ids = var.vpc_public_subnet_ids

  tags = {
    Name = "db-subnet-group-${var.database_name}-${var.environment}"
  }
}

locals {
  db_instance_identifier = "${var.database_name}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "mysql_database_error" {
  name              = "/aws/rds/instance/${local.db_instance_identifier}/error"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "mysql_database_general" {
  name              = "/aws/rds/instance/${local.db_instance_identifier}/general"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "mysql_database_slowquery" {
  name              = "/aws/rds/instance/${local.db_instance_identifier}/slowquery"
  retention_in_days = var.log_retention_days
}

resource "aws_db_instance" "mysql_database" {
  instance_class = var.instance_type
  identifier     = local.db_instance_identifier
  name           = var.database_name
  multi_az       = var.multi_az

  allocated_storage = var.database_size_gb
  storage_type      = var.storage_type

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.storage_encrypted ? var.kms_key_arn : null

  engine               = "mysql"
  engine_version       = "8.0"
  parameter_group_name = "default.mysql8.0"

  allow_major_version_upgrade = false
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = var.backup_retention_period_days
  copy_tags_to_snapshot       = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false == var.deletion_protection
  final_snapshot_identifier = "${var.database_name}-${var.environment}-final-snapshot"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 0

  iam_database_authentication_enabled = false
  username                            = "${var.database_name}_${var.environment}"
  password                            = var.database_password

  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.public_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Environment = var.environment
  }

  depends_on = [ # The logs get put into the log group whose name matches ours, so we need to set an explicit dependency
    aws_cloudwatch_log_group.mysql_database_error,
    aws_cloudwatch_log_group.mysql_database_general,
    aws_cloudwatch_log_group.mysql_database_slowquery
  ]
}

# Init the database with a script to create tables/indexes/etc

# Put the password in a local file, readable only by us, because passing it on the command line or in an env var is insecure and can be sniffed by programs such as ps:
# https://dev.mysql.com/doc/mysql-security-excerpt/8.0/en/password-security-user.html

resource "local_file" "mysql_password" {
  filename          = "${path.cwd}/mysql_password" # Use current working directory rather than the usual path.module so that we can have separate passwords for dev/prod
  file_permission   = "0600"
  sensitive_content = "[client]\npassword=${var.database_password}"
}

resource "null_resource" "init-database" {
  triggers = {
    database_id = aws_db_instance.mysql_database.id # Run this every time the database is changed
  }

  provisioner "local-exec" {
    command = "mysql --defaults-file=${local_file.mysql_password.filename} --host=${aws_db_instance.mysql_database.address} --port=${aws_db_instance.mysql_database.port} --user=${aws_db_instance.mysql_database.username} --database=${aws_db_instance.mysql_database.name} < ../modules/${var.init_script_file}"
  }
}
