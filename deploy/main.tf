terraform {
  backend "s3" {
    region = "eu-west-1"
    bucket = "tekis-demo-bucket"
    key    = "demo-bucket-state"
  }
}

provider "aws" {
  profile = "tekis"
  region = "eu-west-1"
}

data "aws_vpc" "tekis_vpc" {
  filter {
    name   = "tag:Name"
    values = ["tekis-VPC"]
  }
}
data "aws_subnet_ids" "tekis_private_subnets" {
  vpc_id = "${data.aws_vpc.tekis_vpc.id}"
  filter {
    name   = "tag:Name"
    values = ["tekis-private-subnet-1a", "tekis-private-subnet-1b"]
  }
}

data "aws_ecr_repository" "demo_service_repo" {
  name = "demo"
}

data "aws_lb" "tekis_lb" {
  name = "tekis-loadbalancer-1"
}

data "aws_lb_listener" "tekis_lb_listener" {
  load_balancer_arn = "${data.aws_lb.tekis_lb.arn}"
  port = 443
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "christina-regina"
}

resource "aws_iam_role" "demo_service_execution_role" {
  name               = "demo-service-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "demo_service_execution_role_policy" {
  name = "demo-service-execution-role-policy"
  role = "${aws_iam_role.demo_service_execution_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_security_group" "demo_service_task_sg" {
  name   = "demo-service-task-sg"
  vpc_id = "${data.aws_vpc.tekis_vpc.id}"

  ingress {
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "demo_service_lb_target_group" {
  name        = "demo-service-target-group"
  port        = 5050
  protocol    = "HTTP"
  vpc_id      = "${data.aws_vpc.tekis_vpc.id}"
  target_type = "ip"

  health_check {
    path = "/health"
    matcher = 200
  }
}

resource "aws_alb_listener_rule" "demo_service_listener_rule" {
  listener_arn = "${data.aws_lb_listener.tekis_lb_listener.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.demo_service_lb_target_group.arn}"
  }

  condition {
    path_pattern {
      values = ["/demoapp"]
    }
  }
}

resource "aws_cloudwatch_log_group" "demo_service_cw" {
  name = "/ecs/christina-regina/demo-service"
}

resource "aws_ecs_task_definition" "demo_service_task" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${aws_iam_role.demo_service_execution_role.arn}"
  container_definitions    = <<DEFINITION
[
  {
    "name": "demo_service_task",
    "image": "${data.aws_ecr_repository.demo_service_repo.repository_url}:latest",
    "cpu": 256,
    "memory": null,
    "memoryReservation": null,
    "essential": true,
    "portMappings": [{
      "containerPort": 5050,
      "hostPort": 5050,
      "protocol": "tcp"
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.demo_service_cw.name}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "ecs",
        "awslogs-datetime-format": "%Y-%m-%d %H:%M:%S"
      }
    },
    "environment": [
      {"name": "PORT", "value": "5050"}
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "event_service" {
  name            = "demo-service"
  cluster         = "${data.aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.demo_service_task.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.demo_service_task_sg.id}"]
    subnets         = "${data.aws_subnet_ids.tekis_private_subnets.ids}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.demo_service_lb_target_group.arn}"
    container_name   = "demo_service_task"
    container_port   = 5050
  }

  depends_on = [
    aws_alb_target_group.demo_service_lb_target_group
  ]
}
