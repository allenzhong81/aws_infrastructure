terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

resource "aws_security_group" "public_alb_sg" {
  name        = "public_alb_sg"
  description = "security group to allow traffic via alb"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0 
    to_port     = 0 
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "public_alb" {
  name            = var.alb_name
  security_groups = [aws_security_group.public_alb_sg.id]
  subnets         = var.alb_public_subnets_ids
}

resource "aws_alb_target_group" "default" {
  name     = "default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# resource "aws_alb_listener" "this" {
#   load_balancer_arn = "${aws_alb.public_alb.arn}"
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = "${aws_alb_target_group.default.arn}"
#   }
# }
