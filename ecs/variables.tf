variable "app_name" {
  description = "Name of ECS Cluster"
}
variable "image_url" {
}
variable "log_group_region" {
}
variable "log_group_name" {
}
variable "log_group_prefix" {
}
variable "container_port" {
  default = 80
  description = "Port that the container listens on"
}
variable "host_port" {
  default = 80
  description = "Port that host listens on" 
}

variable "container_name" {
  description = "Name of container"
}

variable "cpu" {
  default = "256"
}

variable "memory" {
  default = "512"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "task_name" {
  description = "Name of the task"
}

variable "desired_count" {
  description = "Desired count of task in service" 
  default = 2
}
variable "subnets" {
  description = "Subnets that run containers" 
  default = []
}

variable "alb_arn" {
  description = "ALB Arn"
}
variable "vpc_id" {
  description = "Vpc id" 
}
variable "service_path" {
  description = "Service Path" 
  default = "*"
}
variable "health_check_path" {
  description = "Health Check Path"
  default = "/health" 
}
variable "https_enabled" {
  description = "Enable HTTPS"
  default = false 
}

variable "certificate_arn" {
  description = "certificate arn" 
  default = ""
}

variable "public_alb_sg_group_ids" {
  description = "security group ids of defining in public alb" 
}

variable "task_definition_family" {
  description = "Task definition family" 
}

variable "service_name" {
  description = "Service Name" 
}




