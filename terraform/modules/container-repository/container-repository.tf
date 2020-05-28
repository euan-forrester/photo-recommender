resource "aws_ecr_repository" "ecr" {
  name = "${var.name}-${var.environment}"
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.ecr.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than N days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": ${var.num_days_to_keep_images}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

}

