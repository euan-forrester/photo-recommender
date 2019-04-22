resource "aws_ecr_repository" "ecr" {
    name = "ingester-database-${var.environment}"
} 