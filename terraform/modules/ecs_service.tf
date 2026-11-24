
# Shared network configuration for ECS services
locals {
  ecs_subnets = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  ecs_security_groups = [
    aws_security_group.ecs.id
  ]
}

# ECS service for staging
resource "aws_ecs_service" "staging" {
  name            = "${var.project_name}-staging-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.staging.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.ecs_subnets
    security_groups  = local.ecs_security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
    container_name   = "sessions-api"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  depends_on = [
    aws_lb_listener.staging,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_secret_access
  ]

  tags = {
    Name        = "${var.project_name}-staging-service"
    Environment = "staging"
  }
}

# ECS service for production
resource "aws_ecs_service" "production" {
  name            = "${var.project_name}-production-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.production.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Spread production tasks across Availability Zones
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  network_configuration {
    subnets          = local.ecs_subnets
    security_groups  = local.ecs_security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.production.arn
    container_name   = "sessions-api"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 60

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  depends_on = [
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_execution,
    aws_iam_role_policy.ecs_secret_access
  ]

  tags = {
    Name        = "${var.project_name}-production-service"
    Environment = "production"
  }
}