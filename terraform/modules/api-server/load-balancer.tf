resource "aws_lb" "api_server" {
    depends_on         = ["aws_s3_bucket.load_balancer_access_logs"]

    name               = "api-server-lb-${var.environment}"
    internal           = false
    load_balancer_type = "application"
    security_groups    = ["${aws_security_group.load_balancer.id}"]
    subnets            = ["${var.vpc_public_subnet_ids}"]
    idle_timeout       = 60
    ip_address_type    = "ipv4"

    access_logs {
        bucket  = "${var.load_balancer_access_logs_bucket}-${var.environment}"
        prefix  = "${var.load_balancer_access_logs_prefix}-${var.environment}"
        enabled = true
    }

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
        matcher             = "200"
    }

    depends_on              = ["aws_lb.api_server"] # https://github.com/cds-snc/aws-ecs-fargate/issues/1
}

resource "aws_lb_listener" "api_server" {  
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
            "0.0.0.0/0" # internet-facing load balancer should accept traffic from everywhere: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html
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

# Setup bucket policy so load balancer can write to it.
# Taken from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html

data "aws_caller_identity" "load_balancer" {}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "load_balancer_access_logs" {
    bucket = "${var.load_balancer_access_logs_bucket}-${var.environment}"
    acl    = "bucket-owner-full-control"
    force_destroy = "${!var.retain_load_balancer_access_logs_after_destroy}"
    policy = <<EOF
{
  "Id": "Policy1429136655940",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowToPutLoadBalancerLogsToS3Bucket",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.load_balancer_access_logs_bucket}-${var.environment}/${var.load_balancer_access_logs_prefix}-${var.environment}/AWSLogs/${data.aws_caller_identity.load_balancer.account_id}/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.id}"
        ]
      }
    }
  ]
}
    EOF

    lifecycle_rule {
        id      = "expire-logs-after-N-days"
        enabled = true

        prefix = "*"

        expiration {
            days = "${var.load_balancer_days_to_keep_access_logs}"
        }
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                # It seems that the ALB isn't able to write to the bucket if we set this to "aws:kms": 
                # we get an error saying "Failure configuring LB attributes: InvalidConfigurationRequest: Access Denied for bucket". 
                # It also seems to be implied by the docs here that we need to use AES: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
                sse_algorithm = "AES256" 
            }
        }
    }
}

resource "aws_s3_bucket_public_access_block" "load_balancer_access_logs" {
    bucket = "${aws_s3_bucket.load_balancer_access_logs.id}"

    block_public_acls         = true
    block_public_policy       = true
    ignore_public_acls        = true
    restrict_public_buckets   = true
}