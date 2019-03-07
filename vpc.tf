provider "aws" {
    region = "ap-southeast-1"
    version = "~> 1.60"
}

resource "aws_eip" "eips" {
  count = 3
  vpc = true
}

module "vpc" {
    source = "./vpc"

    vpc_name = "allen-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
    private_subnets  = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]

    reuse_nat_ips = true
    external_nat_ip_ids = ["${aws_eip.eips.*.id}"]
    enable_nat_gateway = true 
    enable_nat_instance = false 

    single_nat_gateway = true
    single_nat_instance = false 

    one_nat_gateway_per_az = false 
    one_nat_instance_per_az = false 
    one_public_route_table_per_az = false 

    aws_key_name = "key_for_new_infras"
    tags = {
        Terraform = "true"
        Environment = "dev"
    }
}

output "eips" {
  value = ["${module.vpc.eips}"]
}
