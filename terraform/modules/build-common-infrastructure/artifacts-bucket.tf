resource "aws_kms_key" "build_artifacts" {
    description             = "Used to encrypt/decrypt codepipeline build artifacts"
    key_usage               = "ENCRYPT_DECRYPT"
    enable_key_rotation     = true
    deletion_window_in_days = 7
}

resource "aws_s3_bucket" "build_artifacts" {
  bucket = "${var.build_artifacts_bucket}${var.bucketname_user_string}-${var.environment}"
  acl    = "private"
  force_destroy = "true"

  lifecycle_rule {
    id      = "expire-artifacts-after-N-days"
    enabled = true

    prefix = "*"

    expiration {
      days = "${var.days_to_keep_build_artifacts}"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "build_artifacts" {
    bucket = "${aws_s3_bucket.build_artifacts.id}"

    block_public_acls         = true
    block_public_policy       = true
    ignore_public_acls        = true
    restrict_public_buckets   = true
}