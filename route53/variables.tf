variable "alb_dns_name" {
  description = "DNS Name of ALB to be alias of record in Route53"
}

variable "alb_zone_id" {
  description = "Zone ID of ALB to be alias of record in Route53"
}

variable "main_zone_name" {
  description = "Main Zone name"
}

variable "app_zone_name" {
  description = "App zone name" 
}

variable "app_record_name" {
  description = "App record name"
}


