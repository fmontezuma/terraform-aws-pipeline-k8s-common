data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${format("%.63s", "${data.aws_caller_identity.current.account_id}-pipe-k8s-common-${var.k8s_deploy_branch}")}"
  acl    = "private"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "k8s-common-${var.k8s_deploy_branch}"
  role_arn = "${var.codepipeline_role_arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner  = "fmontezuma"
        Repo   = "helm-chart"
        Branch = "${var.helm_repo_env}"
      }
    }
  }

  stage {
    name = "PushChanges"

    action {
      name             = "PushChangesToK8sDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.deploy.name}"
      }
    }
  }

}
