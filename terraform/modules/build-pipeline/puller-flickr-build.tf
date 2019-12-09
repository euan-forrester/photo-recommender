# Sample for building docker images: https://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html

data "aws_caller_identity" "build-pipeline" {
  
}

resource "aws_codebuild_project" "puller-flickr" {
  name          = "puller-flickr-${var.environment}"
  description   = "Builds the ${var.environment} puller-flickr container"
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
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # For building docker images
  
    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment_long_name}"
    }

    # These needed for building docker images

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${var.region}"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${data.aws_caller_identity.build-pipeline.account_id}"
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "${var.puller_flickr_ecr_repo_name}"
    }
  }

  logs_config {
    
    cloudwatch_logs {
      status = "DISABLED"
    }

    s3_logs {
      status = "ENABLED"
      location = "${aws_s3_bucket.build_logs.id}/puller-flickr"
    }
  }

  source {
    type            = "GITHUB"
    location        = "${var.project_github_location}"
    buildspec       = "backend/puller-flickr/buildspec.yml"
    git_clone_depth = 1
  }

  tags = {
    Environment = "${var.environment}"
  }

  # It would be preferable to have these builds happen in our own VPC, but the machines have to
  # be on a private subnet with access to the Internet, which requires a NAT, which incurs billing charges.
  # So just have them be in the default VPC instead
}

resource "aws_codebuild_webhook" "puller-flickr" {
  project_name = "${aws_codebuild_project.puller-flickr.name}"

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
      pattern = "backend/puller-flickr/*"
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
      pattern = "backend/common/*"
    }
  }
}
