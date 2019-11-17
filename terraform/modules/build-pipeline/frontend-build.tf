resource "aws_codebuild_project" "frontend" {
  name          = "frontend-${var.environment}"
  description   = "Builds the ${var.environment} frontend"
  build_timeout = "5"
  service_role  = "${aws_iam_role.build_pipeline.arn}"
  badge_enabled = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    
    cloudwatch_logs {
      status = "DISABLED"
    }

    s3_logs {
      status = "ENABLED"
      location = "${aws_s3_bucket.build_logs.id}/frontend"
    }
  }

  source {
    type            = "GITHUB"
    location        = "${var.project_github_location}"
    git_clone_depth = 1
  }

  vpc_config {
    vpc_id = "${var.vpc_id}"
    subnets = ["${var.vpc_subnet_ids}"]
    security_group_ids = ["${aws_security_group.code_build.id}"]
  }

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_codebuild_webhook" "example" {
  project_name = "${aws_codebuild_project.frontend.name}"

  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type = "HEAD_REF"
      pattern = "master"
    }

    filter {
      type = "FILE_PATH"
      pattern = "/frontend/*"
    }
  }
}
