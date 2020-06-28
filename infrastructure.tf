provider "aws" {
  region  = "ap-southeast-2"
  # version = "~> 1.60"
}

resource "aws_eip" "eips" {
  count = 3
  vpc   = true
}

module "vpc" {
  source = "./vpc"

  vpc_name = "allen-vpc"
  cidr     = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  reuse_nat_ips       = true
  external_nat_ip_ids = "${aws_eip.eips.*.id}"
  enable_nat_gateway  = true 
  enable_nat_instance = false 

  single_nat_gateway  = false
  single_nat_instance = false

  one_nat_gateway_per_az        = false
  one_nat_instance_per_az       = true 
  one_public_route_table_per_az = true 

  aws_key_name = "key_for_new_infras"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "alb" {
  source   = "./alb"
  alb_name = "allen-alb"
  vpc_id   = "${module.vpc.vpc_id}"

  alb_public_subnets_ids = "${module.vpc.public_subnets_ids}"
}

module "log_group" {
  source = "./log_group"
  log_group_region = "ap-southeast-2"
  log_group_name = "/ecs/myservice"
  log_stream_prefix = "ecs"
}

module "ecs" {
  source = "./ecs"

  app_name = "my-service"

  vpc_id = "${module.vpc.vpc_id}"

  service_path = "*"

  health_check_path = "/"

  https_enabled = false

  image_url = "hello-world"

  service_name = "my_service"

  task_definition_family = "my_task_family"

  container_name = "my_container"

  container_port = 80
  host_port = 80

  task_name = "my_service_task"
  public_alb_sg_group_ids = "${module.alb.alb_security_group_id}"
  ecs_service_egress_sg_ids = "${module.vpc.nat_security_group_ids}"
  subnets = "${module.vpc.private_subnets_ids}"
  alb_arn = "${module.alb.public_alb_arn}"
  log_group_region = "${module.log_group.log_group_region}"
  log_group_name = "${module.log_group.log_group_name}"
  log_stream_prefix = "${module.log_group.log_stream_prefix}"
}

module "codedeploy" {
  source                     = "git::https://github.com/allenzhong81/terraform-aws-codedeploy-for-ecs.git"
  name                       = "allen-deploy"
  ecs_cluster_name           = module.ecs.ecs_cluster_name
  ecs_service_name           = module.ecs.ecs_service_name
  lb_listener_arns           = ["${module.ecs.alb_listener_arn}"]
  blue_lb_target_group_name  = module.ecs.aws_alb_green_target_group_name 
  green_lb_target_group_name = module.ecs.aws_alb_blue_target_group_name 

  # auto_rollback_enabled            = true
  # auto_rollback_events             = ["DEPLOYMENT_FAILURE"]
  # action_on_timeout                = "STOP_DEPLOYMENT"
  # wait_time_in_minutes             = 20
  # termination_wait_time_in_minutes = 20
  # test_traffic_route_listener_arns = []
  # iam_path                         = "/service-role/"
  # description                      = "This is example"

  tags = {
    Environment = "prod"
  }
}

output "eips" {
  value = "${module.vpc.eips}"
}

output "public_alb_arn" {
  value = "${module.alb.public_alb_arn}"
}
