##################################
## IAM
##################################
resource "aws_iam_role" "ecs_service" {
  name = "${vars.ecs_role_name}"
  assume_role_policy = <<EOF
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "ecs.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "ecs_service" {
  name = "${vars.ecs_role_policy_name}"
  role = "${aws_iam_role.ecs_service.name}"

	policy = <<EOF
		{
			"Version": "2012-10-17",
			"Statement": [
				{
					"Effect": "Allow",
					"Action": [
						"ec2:Describe*",
						"elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
						"elasticloadbalancing:DeregisterTargets",
						"elasticloadbalancing:Describe*",
						"elasticloadbalancing:RegisterInstancesWithLoadBalancer",
						"elasticloadbalancing:RegisterTargets"
					],
					"Resource": "*"
				}
			]
		}
	EOF
}

/*
* IAM service role
*/
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = "${data.aws_iam_policy_document.ecs_service_policy.json}"
  role   = "${aws_iam_role.ecs_role.id}"
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = "${file("${path.module}/policies/ecs-task-execution-role.json")}"
}

resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = "${file("${path.module}/policies/ecs-execution-role-policy.json")}"
  role   = "${aws_iam_role.ecs_execution_role.id}"
}


##################################
## ECS 
##################################
resource "aws_ecs_cluster" "main" {
  name = "${vars.name}"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url        = "${vars.image_url}"
    container_name   = "${vars.container_name}"
    log_group_region = "${vars.log_group_region}"
    log_group_name   = "${vars.log_group_name}"
    log_group_prefix = "${vars.log_group_prefix}"
  }
}


resource "aws_ecs_task_definition" "this" {
  family                = "${vars.task_definition_family}"
  container_definitions = "${data.template_file.task_definition.rendered}"
  requires_compatibilities =  ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"
}

resource "aws_ecs_service" "this" {
  name            = "${vars.service_name}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.this.arn}"
  desired_count   = 3
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.test.id}"
    container_name   = "${vars.container_name}"
    container_port   = "8000"
  }

  network_configuration {
    security_groups = ["${aws_security_group.ecs_service.id}"]
    subnets         = ["${aws_subnet.main.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy.ecs_service",
    "aws_alb_listener.front_end",
  ]
}