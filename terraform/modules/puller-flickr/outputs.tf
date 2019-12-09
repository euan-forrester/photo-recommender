output "repository_name" {
    value = "${module.container_repository.repository_name}"
    description = "The name of the repository that was created"
}