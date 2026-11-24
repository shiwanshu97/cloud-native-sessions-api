
variable "project_name" {
  description = "Name used to identify project resources"
  type        = string
  default     = "sessions-api"
}

variable "vpc_cidr" {
  description = "CIDR range for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS region used for subnet availability zones"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy from ECR"
  type        = string
  default     = "bootstrap"
}