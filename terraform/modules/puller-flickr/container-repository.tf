resource "aws_ecr_repository" "ecr" {
    name = "puller-flickr-${var.environment}"
} 