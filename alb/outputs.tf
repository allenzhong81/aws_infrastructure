output "public_alb_arn" {
  value = aws_alb.public_alb.arn
}

output "alb_target_group_id" {
  value = aws_alb_target_group.default.id
}

output "alb_target_group_arn" {
  value = aws_alb_target_group.default.arn
}
output "alb_security_group_id" {
  value = aws_security_group.public_alb_sg.id
}

output "dns_name" {
  value = aws_alb.public_alb.dns_name
}

# output "alb_listener_id" {
#   value = "${aws_alb_listener.this.id}"
# } 

# output "alb_listener_arn" {
#   value = "${aws_alb_listener.this.arn}"
# } 

