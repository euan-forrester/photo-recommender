module "build" {
  source = "../build-pipeline-backend"

  environment               = "${var.environment}"
  environment_long_name     = "${var.environment_long_name}"
  region                    = "${var.region}"
  process_name              = "${var.process_name}"
  project_github_location   = "${var.project_github_location}"
  build_logs_bucket_id      = "${var.build_logs_bucket_id}"
  buildspec_location        = "${var.buildspec_location}"
  file_path                 = "${var.file_path}"
  build_service_role_arn    = "${var.build_service_role_arn}"
  container_repository_name = "${module.container_repository.repository_name}"
}