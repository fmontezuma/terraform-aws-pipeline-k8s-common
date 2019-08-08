resource "aws_codebuild_project" "deploy" {
  name          = "${var.project_name}-k8s-common-deploy-${var.k8s_deploy_branch}"
  description   = "Deploy process for K8S Common - ${var.k8s_deploy_branch}"
  service_role  = "${var.codebuild_deploy_role_arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0-1.10.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = "true"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/fmontezuma/helm-chart"
    git_clone_depth = 1
    buildspec = templatefile("${path.module}/deploy-buildspec.json.tpl", { project_name = var.project_name, region = data.aws_region.current.name, k8s_deploy_branch = var.k8s_deploy_branch, helm_repo_env = var.helm_repo_env })
  }
}
