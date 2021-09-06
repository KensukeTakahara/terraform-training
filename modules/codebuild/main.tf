data "aws_caller_identity" "self" {}

resource "aws_codebuild_project" "example" {
  name         = "example"
  service_role = var.service_role_arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:4.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-northeast-1"
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.self.account_id
    }

    environment_variable {
      name  = "IMAGE"
      value = "example:latest"
    }
  }
}
