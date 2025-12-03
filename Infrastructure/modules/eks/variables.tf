variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  type        = string
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

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}



