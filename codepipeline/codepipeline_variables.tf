variable "codepipeline_artifact_bucket_name" {
  type        = string
}

variable "codepipeline_role_name" {
  type        = string
}

variable "codepipeline_role_policy_name" {
  type        = string
}

variable "codepipeline_name" {
  type = string
}

variable "codecommit_repo_name" {
  type = string
}

variable "codebuild_name" {
  type = string
}

variable "codedeploy_application_name" {
  type = string
}

variable "codedeploy_deploymentgroup_name" {
  type = string
}

variable "github_oauthtoken" {
  type = string
}