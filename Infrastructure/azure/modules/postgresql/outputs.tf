# =============================================================================
# POSTGRESQL OUTPUTS
# =============================================================================

output "server_id" {
  description = "The ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "The name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "The FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "administrator_login" {
  description = "The administrator login"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive   = true
}

output "administrator_password" {
  description = "The administrator password"
  value       = var.administrator_password != null ? var.administrator_password : random_password.admin.result
  sensitive   = true
}

output "database_names" {
  description = "Names of created databases"
  value       = [for db in azurerm_postgresql_flexible_server_database.main : db.name]
}

output "connection_string" {
  description = "PostgreSQL connection string template"
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/{database}?sslmode=require"
  sensitive   = true
}
