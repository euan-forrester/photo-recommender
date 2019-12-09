output "repository_url" {
    value = "${aws_ecr_repository.ecr.repository_url}"
    description = "The URL of the respository that was created"
}

output "repository_name" {
    value = "${aws_ecr_repository.ecr.name}"
    description = "The name of the repository that was created"
}