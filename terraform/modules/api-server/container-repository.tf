resource "aws_ecr_repository" "ecr" {
    name = "api-server-${var.environment}"
} 