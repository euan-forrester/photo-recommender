output "security_group_id" {
    value = "${aws_security_group.api_server.id}"
    description = "The ID of the security group we created containing the rules for talking to our API server"
}