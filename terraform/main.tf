terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./modules"

  project_name = "sessions-api"
  vpc_cidr     = "10.0.0.0/16"
  aws_region   = var.aws_region
}