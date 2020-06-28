output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name 
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "aws_alb_green_target_group_name" {
  value = aws_alb_target_group.green.name
}

output "aws_alb_blue_target_group_name" {
  value = aws_alb_target_group.blue.name
}
output "alb_listener_arn" {
  value = aws_alb_listener.http_service[0].arn
}