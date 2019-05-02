module "container_repository" {
    source = "../container-repository"

    name = "api-server"
    environment = "${var.environment}"
    num_days_to_keep_images = "${var.ecs_days_to_keep_images}"
}