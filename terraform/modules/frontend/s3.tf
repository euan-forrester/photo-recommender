resource "aws_s3_bucket" "frontend" {
    bucket = "${var.application_name}${var.bucketname_user_string}-${var.environment}"
    acl    = "bucket-owner-full-control"
    force_destroy = true

    website {
        index_document = "index.html"
        error_document = "index.html"
    }

    logging {
        target_bucket = "${aws_s3_bucket.frontend_access_logs.id}"
        target_prefix = "access-log/"
    }

    lifecycle_rule {
        id      = "expire-old-versions-after-N-days"
        enabled = true

        prefix = "*"

        noncurrent_version_expiration {
            days = "${var.days_to_keep_old_versions}"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
    bucket = "${aws_s3_bucket.frontend.id}"

    block_public_acls         = true
    block_public_policy       = true
    ignore_public_acls        = true
    restrict_public_buckets   = true
}

# We need to give the cloudfront user the ability to read from this bucket, and our current
# user the ability to write to it

# Setting the acl to "bucket-owner-full-control" gives the *account* owner full control, but no control
# to the IAM user who created the bucket. That's the same IAM user who will be deploying files
# into this bucket, so it needs an individual permission

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "allow_cloudfront_and_current_user" {
    statement {
        actions   = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.frontend.arn}/*"]

        principals {
            type        = "AWS"
            identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
        }
    }

    statement {
        actions   = ["s3:ListBucket"]
        resources = ["${aws_s3_bucket.frontend.arn}"]

        principals {
            type        = "AWS"
            identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
        }
    }
}

resource "aws_s3_bucket_policy" "frontend_cloudfront_current_user" {
    bucket = "${aws_s3_bucket.frontend.id}"
    policy = "${data.aws_iam_policy_document.allow_cloudfront_and_current_user.json}"
}

resource "aws_s3_bucket" "frontend_access_logs" {
    bucket = "${var.frontend_access_logs_bucket}${var.bucketname_user_string}-${var.environment}"
    acl    = "log-delivery-write"
    force_destroy = "${!var.retain_frontend_access_logs_after_destroy}"

    lifecycle_rule {
        id      = "expire-logs-after-N-days"
        enabled = true

        prefix = "*"

        expiration {
            days = "${var.days_to_keep_frontend_access_logs}"
        }
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                # Keep this as AES for consistency with the load balancer access logs (see note there)
                sse_algorithm = "AES256" 
            }
        }
    }
}

resource "aws_s3_bucket_public_access_block" "frontend_access_logs" {
    bucket = "${aws_s3_bucket.frontend_access_logs.id}"

    block_public_acls         = true
    block_public_policy       = true
    ignore_public_acls        = true
    restrict_public_buckets   = true
}