variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "banking-app"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_group_config" {
  description = "Node group configuration"
  type = object({
    desired_size    = number
    min_size        = number
    max_size        = number
    instance_types  = list(string)
    disk_size       = number
    capacity_type   = string
  })
}

# RDS Configuration
variable "db_config" {
  description = "RDS database configuration"
  type = object({
    instance_class          = string
    allocated_storage       = number
    max_allocated_storage   = number
    multi_az                = bool
    backup_retention_period = number
    deletion_protection     = bool
  })
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "banking_db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

# Monitoring
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Tags
variable "additional_tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

