resource "aws_s3_bucket" "frontend" {
    bucket = "${var.application_name}-${var.environment}"
    acl    = "public-read"
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

    block_public_acls         = false
    block_public_policy       = false
    ignore_public_acls        = false
    restrict_public_buckets   = false
}

resource "aws_s3_bucket" "frontend_access_logs" {
    bucket = "${var.frontend_access_logs_bucket}-${var.environment}"
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