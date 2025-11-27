locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    },
    var.additional_tags
  )

  # Calculate subnet CIDRs based on VPC CIDR
  vpc_cidr_prefix = split("/", var.vpc_cidr)[0]
  vpc_cidr_suffix = split("/", var.vpc_cidr)[1]
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store DB password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.cluster_name}-db-password"
  description             = "RDS database password for ${var.environment} environment"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "mysql"
    host     = module.rds.db_instance_endpoint
    port     = 3306
    dbname   = var.db_name
  })
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  cluster_name       = local.cluster_name
  environment        = var.environment
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  cluster_name = local.cluster_name
  environment  = var.environment
  
  tags = local.common_tags

  depends_on = [module.vpc]
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name              = local.cluster_name
  cluster_version           = var.cluster_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security.cluster_security_group_id
  
  node_group_config = var.node_group_config
  
  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days
  environment               = var.environment
  
  tags = local.common_tags

  depends_on = [module.vpc, module.security]
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  identifier   = "${local.cluster_name}-db"
  db_name      = var.db_name
  db_username  = var.db_username
  db_password  = random_password.db_password.result
  
  db_config = var.db_config
  
  vpc_id                 = module.vpc.vpc_id
  database_subnet_ids    = module.vpc.database_subnet_ids
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  db_security_group_id   = module.security.db_security_group_id
  
  environment = var.environment
  tags        = local.common_tags

  depends_on = [module.vpc, module.security]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name       = local.cluster_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
  
  tags = local.common_tags

  depends_on = [module.eks]
}

