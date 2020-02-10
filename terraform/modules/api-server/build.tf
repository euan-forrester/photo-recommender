module "build" {
  source = "../build-pipeline-backend"

  environment               = "${var.environment}"
  region                    = "${var.region}"
  process_name              = "${var.process_name}"
  project_github_location   = "${var.project_github_location}"
  build_logs_bucket_id      = "${var.build_logs_bucket_id}"
  buildspec_location        = "${var.buildspec_location}"
  file_path                 = "${var.file_path}"
  file_path_common          = "${var.file_path_common}"
  build_service_role_arn    = "${var.build_service_role_arn}"
  container_repository_name = "${module.container_repository.repository_name}"
  build_artifacts_bucket_id = "${var.build_artifacts_bucket_id}"
  build_artifacts_encryption_key_id = "${var.build_artifacts_encryption_key_id}"
  pipeline_service_role_arn = "${var.pipeline_service_role_arn}"
  ecs_service_name          = "${module.task_definition.service_name}"
  ecs_cluster_name          = "${var.ecs_cluster_name}"
}