variable "vpc_id" {
  description = "Vpc Id"
}

variable "alb_name" {
  description = "Alb name"
}

variable "alb_public_subnets_ids" {
  default     = []
  description = "A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type network."
}

variable "alb_idle_timeout_seconds" {
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle."
}
