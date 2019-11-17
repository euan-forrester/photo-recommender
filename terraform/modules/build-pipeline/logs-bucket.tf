resource "aws_s3_bucket" "build_logs" {
  bucket = "${var.build_logs_bucket}${var.bucketname_user_string}-${var.environment}"
  acl    = "private"
  force_destroy = "${!var.retain_build_logs_after_destroy}"

  lifecycle_rule {
    id      = "expire-logs-after-N-days"
    enabled = true

    prefix = "*"

    expiration {
      days = "${var.days_to_keep_build_logs}"
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