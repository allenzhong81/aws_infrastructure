resource "aws_security_group" "ecs_service" {
  vpc_id      = "${vars.vpc_id}"
  name        = "tf-ecs-service-sg"
  description = "Allows access to container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 65532
    protocol        = "tcp"
    security_groups = ["${vars.public_alb_sg_group_ids}"]
  }

  ingress {
    from_port       = 0
    to_port         = 65532
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_service.id}"]
  }
}

//Health check configuration needed!!!!!!
resource "aws_alb_target_group" "service" {
  name     = "${vars.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    interval = 6
    path = "${vars.health_check_path}"
    protocol = "http"
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_alb_listener" "service" {
  load_balancer_arn = "${vars.alb_arn}"
  path              = "${vars.service_path}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${vars.certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.service.arn}"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${vars.app_name}"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/tasks/task-definition.json")}"

  vars {
    image_url        = "${vars.image_url}"
    container_name   = "${vars.container_name}"
    log_group_region = "${vars.log_group_region}"
    log_group_name   = "${vars.log_group_name}"
    log_group_prefix = "${vars.log_group_prefix}"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${vars.task_definition_family}"
  container_definitions    = "${data.template_file.task_definition.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${vars.cpu}"
  memory                   = "${vars.memory}"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"
}

resource "aws_ecs_service" "this" {
  name            = "${vars.service_name}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.this.arn}"
  desired_count   = "${vars.desired_count}"
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.service.id}"
    container_name   = "${vars.container_name}"
    container_port   = "${vars.container_port}"
  }

  network_configuration {
    security_groups = ["${aws_security_group.ecs_service.id}"]
    subnets         = ["${vars.subnets}"]
  }
}
