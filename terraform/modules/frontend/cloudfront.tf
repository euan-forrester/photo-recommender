# This is a special user that Cloudfront assumes when reading from the bucket. We set our bucket
# permissions such that only this user has access, rather than making it publicly readable,
# so that people can't directly access the bucket contents.
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Cloudfront user allowed to read from our S3 bucket"
}

locals {
  s3_origin_id            = "static_files_origin"
  load_balancer_origin_id = "load_balancer_origin"
  application_domains     = [var.application_domain]
}

resource "aws_cloudfront_distribution" "application" {
  enabled             = true
  default_root_object = "index.html"
  aliases = slice(
    local.application_domains,
    0,
    var.use_custom_domain ? length(local.application_domains) : 0,
  ) # Needs to optionally be an empty list. Workaround from: https://github.com/hashicorp/terraform/issues/18259

  # Our S3 bucket
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  # Our load balancer
  origin {
    domain_name = var.load_balancer_dns_name
    origin_id   = local.load_balancer_origin_id

    custom_origin_config {
      http_port                = var.load_balancer_port
      https_port               = var.load_balancer_port
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_keepalive_timeout = 30 # Max is 60
      origin_read_timeout      = 10 # Max is 60
    }
  }

  # Forward requests beginning with /api to our load balancer
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.load_balancer_origin_id

    forwarded_values {
      query_string = true
      headers      = ["*"] # This seems to be the magic that makes cloudfront not cache anything from this origin, 

      # despite having set the TTLs to 0: https://aws.amazon.com/premiumsupport/knowledge-center/prevent-cloudfront-from-caching-files/
      # This makes a special note appear in the UI saying that cacheing is disabled for this origin.

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  # Forward everything else to our S3 bucket
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.frontend_access_logs.bucket_domain_name
    prefix          = "cloudfront/"
  }

  price_class = "PriceClass_100" # Only serve from US/Europe to keep costs down: https://aws.amazon.com/cloudfront/pricing/

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.use_custom_domain == false                           # In dev, for now, we can just visit our site through cloudfront directly rather than through a domain
    acm_certificate_arn            = element(concat(aws_acm_certificate_validation.cert.*.certificate_arn, [""]), 0) # There's either 1 or 0 certs, so the 0th element is either the cert or empty string
    ssl_support_method             = var.use_custom_domain ? "sni-only" : ""                  # If cloudfront_default_certificate is set then this won't be set. But terraform will try to set it everytime it runs, which takes a good 15 minutes each time
  }
}

