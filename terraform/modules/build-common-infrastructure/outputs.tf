output "build_service_role_arn" {
    value = "${aws_iam_role.build_role.arn}"
    description = "ARN for the role which is used to run builds"
}

output "pipeline_service_role_arn" {
    value = "${aws_iam_role.pipeline_role.arn}"
    description = "ARN for the role which is used to run the pipeline"
}

output "build_logs_bucket_id" {
    value = "${aws_s3_bucket.build_logs.id}"
    description = "ID of the bucket that will contain our build logs"
}

output "build_artifacts_bucket_id" {
    value = "${aws_s3_bucket.build_artifacts.id}"
    description = "ID of the bucket that will contain our build artifacts"
}

output "build_artifacts_encryption_key_id" {
    value = "${aws_kms_key.build_artifacts.id}"
    description = "ID of the KMS key that will be used to encrypt our build artifacts"
}