# =============================================================================
# AZURE DATABASE FOR MYSQL FLEXIBLE SERVER MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# -----------------------------------------------------------------------------
# RANDOM PASSWORD
# -----------------------------------------------------------------------------

resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# MYSQL FLEXIBLE SERVER
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_server" "main" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.mysql_version
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password != null ? var.administrator_password : random_password.admin.result

  sku_name                     = var.sku_name
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  zone = var.availability_zone

  dynamic "high_availability" {
    for_each = var.high_availability_mode != "Disabled" ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 2
    start_minute = 0
  }

  storage {
    size_gb            = var.storage_size_gb
    iops               = var.storage_iops
    auto_grow_enabled  = var.storage_auto_grow_enabled
    io_scaling_enabled = var.io_scaling_enabled
  }

  dynamic "identity" {
    for_each = var.enable_customer_managed_key ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

# -----------------------------------------------------------------------------
# DATABASES
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_database" "main" {
  for_each = toset(var.databases)

  name                = each.key
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  charset             = var.database_charset
  collation           = var.database_collation
}

# -----------------------------------------------------------------------------
# SERVER CONFIGURATIONS
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_server_configuration" "require_ssl" {
  name                = "require_secure_transport"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "tls_version" {
  name                = "tls_version"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "TLSv1.2,TLSv1.3"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log" {
  count = var.enable_audit_log ? 1 : 0

  name                = "audit_log_enabled"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "audit_log_events" {
  count = var.enable_audit_log ? 1 : 0

  name                = "audit_log_events"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "CONNECTION,DDL,DML,DCL"
}

resource "azurerm_mysql_flexible_server_configuration" "slow_query_log" {
  name                = "slow_query_log"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "long_query_time" {
  name                = "long_query_time"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = var.slow_query_time
}

resource "azurerm_mysql_flexible_server_configuration" "log_queries_not_using_indexes" {
  name                = "log_queries_not_using_indexes"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = "ON"
}

resource "azurerm_mysql_flexible_server_configuration" "innodb_buffer_pool_size" {
  count = var.innodb_buffer_pool_size != null ? 1 : 0

  name                = "innodb_buffer_pool_size"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = var.innodb_buffer_pool_size
}

resource "azurerm_mysql_flexible_server_configuration" "max_connections" {
  count = var.max_connections != null ? 1 : 0

  name                = "max_connections"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  value               = var.max_connections
}

# -----------------------------------------------------------------------------
# FIREWALL RULES
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name                = "AllowAzureServices"
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allowed_ips" {
  for_each = var.allowed_ip_addresses

  name                = each.key
  server_name         = azurerm_mysql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  start_ip_address    = each.value.start_ip
  end_ip_address      = each.value.end_ip
}

# -----------------------------------------------------------------------------
# ACTIVE DIRECTORY ADMIN
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_server_active_directory_administrator" "main" {
  count = var.aad_admin_object_id != null ? 1 : 0

  server_id   = azurerm_mysql_flexible_server.main.id
  identity_id = var.aad_admin_identity_id
  login       = var.aad_admin_login
  object_id   = var.aad_admin_object_id
  tenant_id   = var.tenant_id
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "mysql" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mysql_flexible_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "MySqlSlowLogs" }
  enabled_log { category = "MySqlAuditLogs" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
