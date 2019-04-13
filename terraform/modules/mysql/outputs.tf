output "database_endpoint" {
    value = "${aws_db_instance.mysql_database.endpoint}"
    description = "The endpoint of the database that was created in host:port format"
}