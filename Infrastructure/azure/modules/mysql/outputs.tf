# =============================================================================
# MYSQL OUTPUTS
# =============================================================================

output "server_id" {
  description = "The ID of the MySQL server"
  value       = azurerm_mysql_flexible_server.main.id
}

output "server_name" {
  description = "The name of the MySQL server"
  value       = azurerm_mysql_flexible_server.main.name
}

output "server_fqdn" {
  description = "The FQDN of the MySQL server"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "administrator_login" {
  description = "The administrator login"
  value       = azurerm_mysql_flexible_server.main.administrator_login
  sensitive   = true
}

output "administrator_password" {
  description = "The administrator password"
  value       = var.administrator_password != null ? var.administrator_password : random_password.admin.result
  sensitive   = true
}

output "database_names" {
  description = "Names of created databases"
  value       = [for db in azurerm_mysql_flexible_database.main : db.name]
}

output "connection_string" {
  description = "MySQL connection string template"
  value       = "mysql://${azurerm_mysql_flexible_server.main.administrator_login}@${azurerm_mysql_flexible_server.main.fqdn}:3306/{database}?ssl=true"
  sensitive   = true
}

output "jdbc_connection_string" {
  description = "JDBC connection string for Java applications"
  value       = "jdbc:mysql://${azurerm_mysql_flexible_server.main.fqdn}:3306/{database}?useSSL=true&requireSSL=true"
  sensitive   = true
}

output "replica_capacity" {
  description = "Replica capacity"
  value       = azurerm_mysql_flexible_server.main.replica_capacity
}
