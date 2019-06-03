output "security_group_id" {
    value = "${aws_security_group.api_server.id}"
    description = "The ID of the security group we created containing the rules for talking to our API server"
}

output "load_balancer_host" {
    value = "${aws_lb.api_server.dns_name}"
    description = "The DNS hostname of the load balancer we created"
}

output "load_balancer_port" {
    value = "${var.load_balancer_port}"
    description = "The port the load balancer is listening on"
}