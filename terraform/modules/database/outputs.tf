output "database_host" {
    value = "${module.mysql.database_host}"
    description = "Host string for the database that was created"
}

output "database_port" {
    value = "${module.mysql.database_port}"
    description = "Port for the database that was created"
}

output "database_username" {
    value = "${module.mysql.database_username}"
    description = "Username for the database that was created"
}

output "database_name" {
    value = "${module.mysql.database_name}"
    description = "Name of the database that was created"
}