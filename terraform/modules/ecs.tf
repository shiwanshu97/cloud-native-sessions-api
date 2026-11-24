
# ECR repository for the Sessions API Docker image
resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-api"
  }
}

# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# IAM execution role used by ECS
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# Standard ECS task execution permissions
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow ECS to retrieve both database passwords
resource "aws_iam_role_policy" "ecs_secret_access" {
  name = "${var.project_name}-database-secret-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_db_instance.staging.master_user_secret[0].secret_arn,
        aws_db_instance.production.master_user_secret[0].secret_arn
      ]
    }]
  })
}

# IAM role assigned to the running application
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Shared container configuration
locals {
  api_container_base = {
    name      = "sessions-api"
    image     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "sessions-api"
      }
    }
  }

  staging_database_environment = [
    {
      name  = "DB_HOST"
      value = aws_db_instance.staging.address
    },
    {
      name  = "DB_PORT"
      value = tostring(aws_db_instance.staging.port)
    },
    {
      name  = "DB_NAME"
      value = aws_db_instance.staging.db_name
    },
    {
      name  = "DB_USER"
      value = aws_db_instance.staging.username
    }
  ]

  production_database_environment = [
    {
      name  = "DB_HOST"
      value = aws_db_instance.production.address
    },
    {
      name  = "DB_PORT"
      value = tostring(aws_db_instance.production.port)
    },
    {
      name  = "DB_NAME"
      value = aws_db_instance.production.db_name
    },
    {
      name  = "DB_USER"
      value = aws_db_instance.production.username
    }
  ]
}

# Staging ECS task definition
resource "aws_ecs_task_definition" "staging" {
  family                   = "${var.project_name}-staging"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    merge(local.api_container_base, {
      environment = concat(local.staging_database_environment, [
        {
          name  = "APP_ENV"
          value = "staging"
        }
      ])

      secrets = [{
        name      = "DB_PASSWORD"
        valueFrom = "${aws_db_instance.staging.master_user_secret[0].secret_arn}:password::"
      }]
    })
  ])

  tags = {
    Name        = "${var.project_name}-staging-task"
    Environment = "staging"
  }
}

# Production ECS task definition
resource "aws_ecs_task_definition" "production" {
  family                   = "${var.project_name}-production"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    merge(local.api_container_base, {
      environment = concat(local.production_database_environment, [
        {
          name  = "APP_ENV"
          value = "production"
        }
      ])

      secrets = [{
        name      = "DB_PASSWORD"
        valueFrom = "${aws_db_instance.production.master_user_secret[0].secret_arn}:password::"
      }]
    })
  ])

  tags = {
    Name        = "${var.project_name}-production-task"
    Environment = "production"
  }
}