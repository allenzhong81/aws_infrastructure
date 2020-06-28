resource "aws_cloudwatch_log_group" "this" {
  name = var.log_group_name
}

output "log_group_region" {
  value = var.log_group_region
}


output "log_group_name" {
  value = var.log_group_name
}

output "log_stream_prefix" {
  value = var.log_stream_prefix
}

