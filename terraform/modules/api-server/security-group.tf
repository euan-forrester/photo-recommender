resource "aws_security_group" "api_server" {
  name        = "security-group-api-server-${var.environment}"
  description = "Allow access from our local machine and VPC (i.e. the load balancer) to the port we are listening on"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.api_server_port
    to_port   = var.api_server_port
    protocol  = "tcp"
    cidr_blocks = [
      var.local_machine_cidr,
    ]
  }

  ingress {
    from_port = var.api_server_port
    to_port   = var.api_server_port
    protocol  = "tcp"
    cidr_blocks = [
      var.vpc_cidr,
    ]
  }

  tags = {
    Name = "security-group-api-server-${var.environment}"
  }
}

