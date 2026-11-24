
output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id
  ]
}

output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS databases"
  value       = aws_security_group.rds.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "staging_database_endpoint" {
  description = "Endpoint of the staging PostgreSQL database"
  value       = aws_db_instance.staging.address
}

output "staging_database_secret_arn" {
  description = "Secrets Manager ARN for the staging database password"
  value       = aws_db_instance.staging.master_user_secret[0].secret_arn
}

output "production_database_endpoint" {
  description = "Endpoint of the production PostgreSQL database"
  value       = aws_db_instance.production.address
}

output "production_database_secret_arn" {
  description = "Secrets Manager ARN for the production database password"
  value       = aws_db_instance.production.master_user_secret[0].secret_arn
}

output "database_port" {
  description = "PostgreSQL database port"
  value       = aws_db_instance.production.port
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "production_target_group_arn" {
  description = "ARN of the production target group"
  value       = aws_lb_target_group.production.arn
}

output "staging_target_group_arn" {
  description = "ARN of the staging target group"
  value       = aws_lb_target_group.staging.arn
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.api.certificate_arn
}

output "acm_dns_validation_records" {
  description = "DNS records required to validate the ACM certificate"
  value = [
    for record in aws_acm_certificate.api.domain_validation_options : {
      name  = record.resource_record_name
      type  = record.resource_record_type
      value = record.resource_record_value
    }
  ]
}