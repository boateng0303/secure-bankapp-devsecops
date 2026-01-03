# =============================================================================
# AZURE SQL DATABASE MODULE - OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# SQL Server Outputs
# -----------------------------------------------------------------------------

output "server_id" {
  description = "The ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "server_identity_principal_id" {
  description = "The principal ID of the server's managed identity"
  value       = azurerm_mssql_server.main.identity[0].principal_id
}

output "server_identity_tenant_id" {
  description = "The tenant ID of the server's managed identity"
  value       = azurerm_mssql_server.main.identity[0].tenant_id
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_ids" {
  description = "Map of database names to their IDs"
  value       = { for k, v in azurerm_mssql_database.main : k => v.id }
}

output "database_names" {
  description = "List of database names"
  value       = [for k, v in azurerm_mssql_database.main : v.name]
}

# -----------------------------------------------------------------------------
# Authentication Outputs
# -----------------------------------------------------------------------------

output "administrator_login" {
  description = "The administrator login name"
  value       = azurerm_mssql_server.main.administrator_login
}

output "administrator_password" {
  description = "The administrator password"
  value       = random_password.admin.result
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Connection Strings
# -----------------------------------------------------------------------------

output "connection_string" {
  description = "ADO.NET connection string for the first database"
  value       = length(var.databases) > 0 ? "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${var.databases[0]};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${random_password.admin.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" : null
  sensitive   = true
}

output "connection_strings" {
  description = "Map of database names to their connection strings"
  value = {
    for db in var.databases : db => "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${db};Persist Security Info=False;User ID=${azurerm_mssql_server.main.administrator_login};Password=${random_password.admin.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
  sensitive = true
}

output "jdbc_connection_string" {
  description = "JDBC connection string for the first database"
  value       = length(var.databases) > 0 ? "jdbc:sqlserver://${azurerm_mssql_server.main.fully_qualified_domain_name}:1433;database=${var.databases[0]};user=${azurerm_mssql_server.main.administrator_login}@${azurerm_mssql_server.main.name};password=${random_password.admin.result};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;" : null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Private Endpoint Outputs
# -----------------------------------------------------------------------------

output "private_endpoint_id" {
  description = "The ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.sql[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.sql[0].private_service_connection[0].private_ip_address : null
}
