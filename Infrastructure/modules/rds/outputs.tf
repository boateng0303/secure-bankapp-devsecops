output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_instance_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_resource_id" {
  description = "RDS Resource ID"
  value       = aws_db_instance.main.resource_id
}



