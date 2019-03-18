variable "app_name" {
  description = "Name of ECS Cluster"
}
variable "image_url" {
}
variable "container_name" {
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
}
variable "health_check_path" {
  description = "Health Check Path"
  value = "/health" 
}

