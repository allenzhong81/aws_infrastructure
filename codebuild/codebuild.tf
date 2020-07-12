module "codebuild" {
  source                = "git::https://github.com/cloudposse/terraform-aws-codebuild.git?ref=tags/0.21.0"
  enabled               = var.enabled
  namespace             = var.namespace
  name                  = var.name
  stage                 = var.stage
  build_image           = var.build_image
  build_compute_type    = var.build_compute_type
  build_timeout         = var.build_timeout
  buildspec             = var.buildspec
  delimiter             = var.delimiter
  attributes            = concat(var.attributes, ["build"])
  tags                  = var.tags
  privileged_mode       = var.privileged_mode
  aws_region            = var.aws_region 
  aws_account_id        = var.aws_account_id
  image_repo_name       = var.image_repo_name
  image_tag             = var.image_tag
  environment_variables = var.environment_variables
  badge_enabled         = var.badge_enabled
  cache_type            = var.cache_type
  local_cache_modes     = var.local_cache_modes
}

output "codebuild_project_name" {
  value = module.codebuild.project_name
}
