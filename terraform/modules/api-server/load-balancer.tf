resource "aws_lb" "api_server" {
    name               = "api-server-lb-${var.environment}"
    internal           = false
    load_balancer_type = "application"
    security_groups    = ["${aws_security_group.load_balancer.id}"]
    subnets            = ["${var.vpc_public_subnet_ids}"]
    idle_timeout       = 60
    ip_address_type    = "ipv4"

    #access_logs {
    #    bucket  = "${aws_s3_bucket.load_balancer_access_logs.bucket}"
    #    prefix  = "${var.load_balancer_access_logs_prefix}"
    #    enabled = true
    #}

    tags = {
        Environment = "${var.environment}"
    }
}

resource "aws_lb_target_group" "load_balancer" {
    name                    = "api-server-lb-tg-${var.environment}"
    port                    = "${var.api_server_port}"
    protocol                = "HTTP"
    vpc_id                  = "${var.vpc_id}"
    deregistration_delay    = 300
    slow_start              = 0

    health_check {
        interval            = 30
        path                = "/healthcheck"
        port                = "${var.api_server_port}"
        protocol            = "HTTP"
        timeout             = 6
        healthy_threshold   = 3
        unhealthy_threshold = 3
        matcher             = "200-299"
    }
}

resource "aws_lb_listener" "load_balancer" {  
    load_balancer_arn = "${aws_lb.api_server.arn}"  
    port              = "${var.load_balancer_port}"  
    protocol          = "HTTP"
  
    default_action {    
        target_group_arn = "${aws_lb_target_group.load_balancer.arn}"
        type             = "forward"  
    }
}

resource "aws_security_group" "load_balancer" {
    name        = "security-group-load-balancer-${var.environment}"
    description = "Allow access from our local machine to our load balancer"
    vpc_id      = "${var.vpc_id}"

    ingress {
        from_port   = "${var.load_balancer_port}"
        to_port     = "${var.load_balancer_port}"
        protocol    = "tcp"
        cidr_blocks = [
            "${var.local_machine_cidr}"
        ]
    }

    egress {
        # allow all traffic to private SN
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

    tags { 
        Name = "security-group-load-balancer-${var.environment}"
    }
}
/*
resource "aws_kms_key" "load_balancer_access_logs" {
    description             = "Used to encrypt the load balancer access logs"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_s3_bucket" "load_balancer_access_logs" {
    bucket = "${var.load_balancer_access_logs_bucket}"
    acl    = "private"
    policy = "${data.aws_iam_policy_document.access_logs_bucket.json}"

    lifecycle_rule {
        id      = "log"
        enabled = true

        prefix = "*"

        expiration {
            days = "${var.load_balancer_days_to_keep_access_logs}"
        }
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = "${aws_kms_key.load_balancer_access_logs.arn}"
                sse_algorithm     = "aws:kms"
            }
        }
    }
}

# Setup bucket policy so load balancer can write to it.
# Taken from https://github.com/terraform-aws-modules/terraform-aws-alb/issues/61

data "aws_caller_identity" "load_balancer" {}

data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "access_logs_bucket" {
    statement {
        sid       = "AllowToPutLoadBalancerLogsToS3Bucket"
        actions   = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${var.load_balancer_access_logs_bucket}/${var.load_balancer_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.load_balancer.account_id}/*"]

        principals {
            type        = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_elb_service_account.main.id}:root"]
        }
    }
}
*/
