
# This is a special user that Cloudfront assumes when reading from the bucket. We set our bucket
# permissions such that only this user has access, rather than making it publicly readable,
# so that people can't directly access the bucket contents.
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
    comment = "Cloudfront user allowed to read from our S3 bucket"
}

locals {
    s3_origin_id = "static_files_origin"
    load_balancer_origin_id = "load_balancer_origin"
}

resource "aws_cloudfront_distribution" "application" {
    
    enabled = true
    default_root_object = "index.html"

    # Our S3 bucket
    origin {
        domain_name = "${aws_s3_bucket.frontend.bucket_regional_domain_name}"
        origin_id   = "${local.s3_origin_id}"

        s3_origin_config {
            origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
        }
    }

    # Our load balancer
    origin {
        domain_name = "${var.load_balancer_dns_name}"
        origin_id   = "${local.load_balancer_origin_id}"

        custom_origin_config {
            http_port = "${var.load_balancer_port}"
            https_port = "${var.load_balancer_port}"
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
            origin_keepalive_timeout = 30 # Max is 60
            origin_read_timeout = 10 # Max is 60
        }
    }

    # Forward requests beginning with /api to our load balancer
    ordered_cache_behavior {
        path_pattern     = "/api/*"
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = "${local.load_balancer_origin_id}"

        forwarded_values {
            query_string = true

            cookies {
                forward = "all"
            }
        }

        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 5
        max_ttl                = 5
    }

    # Forward everything else to our S3 bucket
    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD", "OPTIONS"]
        target_origin_id = "${local.s3_origin_id}"

        forwarded_values {
            query_string = true

            cookies {
                forward = "all"
            }
        }

        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    logging_config {
        include_cookies = false
        bucket          = "${aws_s3_bucket.frontend_access_logs.bucket_domain_name}"
        prefix          = "cloudfront/"
    }

    price_class = "PriceClass_100" # Only serve from US/Europe to keep costs down: https://aws.amazon.com/cloudfront/pricing/

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        # For https requests, this allows us to use the cloudfront domain name to access our application.
        # TODO: Needs update when we have our own domain name
        # https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html#viewer-certificate-arguments
        cloudfront_default_certificate = true
    }
}
