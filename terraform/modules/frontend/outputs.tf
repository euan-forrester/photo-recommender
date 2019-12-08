output "s3_deployment_bucket_arn" {
    value = "${aws_s3_bucket.frontend.arn}"
    description = "The ARN of the bucket that hosts our deployment"
}