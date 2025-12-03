# Production Environment Main Configuration

terraform {
  required_version = ">= 1.5.0"
}

# Configure providers
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Use root module
module "infrastructure" {
  source = "../.."

  aws_region         = var.aws_region
  environment        = var.environment
  project_name       = var.project_name
  owner              = var.owner
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  cluster_version    = var.cluster_version
  node_group_config  = var.node_group_config
  db_config          = var.db_config
  db_name            = var.db_name
  db_username        = var.db_username

  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days
  additional_tags           = var.additional_tags
}

# Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.infrastructure.cluster_name
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.infrastructure.configure_kubectl
}

output "db_secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = module.infrastructure.db_secret_arn
}



