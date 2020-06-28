resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name        = "tf-ecs-service-sg"
  description = "Allows access to container"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${var.public_alb_sg_group_ids}"]
  }

  egress {
    from_port   = 0 
    to_port     = 0 
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    
    security_groups = var.ecs_service_egress_sg_ids
  }


  # ingress {
  #   from_port       = 0
  #   to_port         = 0 
  #   protocol        = "-1" 
  #   security_groups = ["${aws_security_group.ecs_service.id}"]
  # }
}

resource "aws_alb_target_group" "green" {
  name     = "${var.app_name}-green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    interval            = 6
    path                = var.health_check_path
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_alb_target_group" "blue" {
  name     = "${var.app_name}-blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    interval            = 6
    path                = var.health_check_path
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_alb_listener" "https_service" {
  count             = var.https_enabled ? 1 : 0
  load_balancer_arn = var.alb_arn

  # path              = "${var.service_path}"
  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }
}

resource "aws_alb_listener" "http_service" {
  count             = !var.https_enabled ? 1 : 0
  load_balancer_arn = var.alb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }
}

resource "aws_alb_listener_rule" "http_service" {
  count        = !var.https_enabled ? 1 : 0
  listener_arn = aws_alb_listener.http_service[count.index].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }

  condition {
    field  = "path-pattern"
    values = ["${var.service_path}"]
  }
}

resource "aws_alb_listener_rule" "https_service" {
  count        = var.https_enabled ? 1 : 0
  listener_arn = aws_alb_listener.https_service[count.index].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }

  condition {
    field  = "path-pattern"
    values = [var.service_path]
  }
}

resource "aws_ecs_cluster" "main" {
  name = var.app_name
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/tasks/task-definition.json")}"

  vars = {
    image_url        = var.image_url
    container_name   = var.container_name
    container_port   = var.container_port
    host_port        = var.host_port
    cpu              = var.cpu
    memory           = var.memory
   log_group_region = var.log_group_region
   log_group_name   = var.log_group_name
   log_stream_prefix = var.log_stream_prefix
  }
}

resource "aws_ecs_task_definition" "service_definition" {
  family                   = var.task_definition_family
  container_definitions    = data.template_file.task_definition.rendered
  requires_compatibilities = ["FARGATE"]
  cpu = var.cpu
  memory = var.memory
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  depends_on = [
    data.template_file.task_definition,
  ]
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 120
  load_balancer {
    target_group_arn = aws_alb_target_group.green.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    security_groups = [ "${aws_security_group.ecs_service.id}"]
    subnets         = var.subnets
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    aws_alb_listener_rule.http_service,
    aws_alb_listener_rule.https_service,
    aws_ecs_task_definition.service_definition,
    aws_iam_role.ecs_role,
    aws_iam_role.ecs_execution_role,
  ]
}
