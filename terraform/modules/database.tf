
# Shared DB subnet group across two Availability Zones
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Private subnets for Sessions API PostgreSQL"

  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Staging PostgreSQL database - Single-AZ
resource "aws_db_instance" "staging" {
  identifier = "${var.project_name}-staging-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "sessions_db"
  username = "sessions_user"
  port     = 5432

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  deletion_protection     = false

  skip_final_snapshot = true

  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-staging-postgres"
    Environment = "staging"
  }
}

# Production PostgreSQL database - Multi-AZ
resource "aws_db_instance" "production" {
  identifier = "${var.project_name}-production-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "sessions_db"
  username = "sessions_user"
  port     = 5432

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = true

  backup_retention_period = 7
  deletion_protection     = true

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-production-final-snapshot"

  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-production-postgres"
    Environment = "production"
  }
}