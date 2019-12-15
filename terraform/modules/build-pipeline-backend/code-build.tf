# Sample for building docker images: https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html

data "aws_caller_identity" "build-pipeline-backend" {
  
}

resource "aws_codebuild_project" "backend" {
  name          = "${var.process_name}-${var.environment}"
  description   = "Builds the ${var.environment} ${var.process_name} container"
  build_timeout = "5"
  service_role  = "${var.build_service_role_arn}"
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
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # For building docker images
  
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${var.region}"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${data.aws_caller_identity.build-pipeline-backend.account_id}"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "${var.container_repository_name}"
    }

    environment_variable {
      name  = "PROCESS_NAME"
      value = "${var.process_name}"
    }
  }

  logs_config {
    
    cloudwatch_logs {
      status = "DISABLED"
    }

    s3_logs {
      status = "ENABLED"
      location = "${var.build_logs_bucket_id}/${var.process_name}"
    }
  }

  source {
    type            = "GITHUB"
    location        = "${var.project_github_location}"
    buildspec       = "${var.buildspec_location}"
    git_clone_depth = 1
  }

  tags = {
    Environment = "${var.environment}"
  }

  # It would be preferable to have these builds happen in our own VPC, but the machines have to
  # be on a private subnet with access to the Internet, which requires a NAT, which incurs billing charges.
  # So just have them be in the default VPC instead
}

resource "aws_codebuild_webhook" "backend" {
  project_name = "${aws_codebuild_project.backend.name}"

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
      pattern = "${var.file_path}"
    }
  }

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
      pattern = "${var.file_path_common}"
    }
  }
}
