# =============================================================================
# AZURE SQL DATABASE MODULE
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
# Random Password for Admin
# -----------------------------------------------------------------------------

resource "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

# -----------------------------------------------------------------------------
# Azure SQL Server
# -----------------------------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.sql_version
  administrator_login          = var.admin_username
  administrator_login_password = random_password.admin.result
  minimum_tls_version          = var.minimum_tls_version

  public_network_access_enabled = var.public_network_access_enabled

  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_object_id != null ? [1] : []
    content {
      login_username              = var.azuread_admin_login
      object_id                   = var.azuread_admin_object_id
      azuread_authentication_only = var.azuread_authentication_only
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Azure SQL Database(s)
# -----------------------------------------------------------------------------

resource "azurerm_mssql_database" "main" {
  for_each = toset(var.databases)

  name                        = each.value
  server_id                   = azurerm_mssql_server.main.id
  collation                   = var.collation
  max_size_gb                 = var.max_size_gb
  sku_name                    = var.sku_name
  zone_redundant              = var.zone_redundant
  read_scale                  = var.read_scale
  read_replica_count          = var.read_replica_count
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  min_capacity                = var.min_capacity

  dynamic "short_term_retention_policy" {
    for_each = var.backup_retention_days > 0 ? [1] : []
    content {
      retention_days           = var.backup_retention_days
      backup_interval_in_hours = var.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = var.enable_long_term_retention ? [1] : []
    content {
      weekly_retention  = var.ltr_weekly_retention
      monthly_retention = var.ltr_monthly_retention
      yearly_retention  = var.ltr_yearly_retention
      week_of_year      = var.ltr_week_of_year
    }
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Custom IP Rules
resource "azurerm_mssql_firewall_rule" "custom" {
  for_each = { for idx, rule in var.firewall_rules : rule.name => rule }

  name             = each.value.name
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

# -----------------------------------------------------------------------------
# Virtual Network Rules (for VNet integration)
# -----------------------------------------------------------------------------

resource "azurerm_mssql_virtual_network_rule" "main" {
  for_each = { for idx, subnet in var.allowed_subnet_ids : idx => subnet }

  name      = "vnet-rule-${each.key}"
  server_id = azurerm_mssql_server.main.id
  subnet_id = each.value
}

# -----------------------------------------------------------------------------
# Private Endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "sql" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  count = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.server_name}-diagnostics"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  for_each = var.enable_diagnostics && var.log_analytics_workspace_id != null ? toset(var.databases) : []

  name                       = "${each.value}-diagnostics"
  target_resource_id         = azurerm_mssql_database.main[each.value].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  metric {
    category = "Basic"
    enabled  = true
  }

  metric {
    category = "InstanceAndAppAdvanced"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# Auditing (optional)
# -----------------------------------------------------------------------------

resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  count = var.enable_auditing ? 1 : 0

  server_id                               = azurerm_mssql_server.main.id
  storage_endpoint                        = var.audit_storage_endpoint
  storage_account_access_key              = var.audit_storage_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.audit_retention_days
  log_monitoring_enabled                  = var.log_analytics_workspace_id != null
}

# -----------------------------------------------------------------------------
# Threat Detection (optional)
# -----------------------------------------------------------------------------

resource "azurerm_mssql_server_security_alert_policy" "main" {
  count = var.enable_threat_detection ? 1 : 0

  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.main.name
  state               = "Enabled"

  email_account_admins = var.threat_detection_email_admins
  email_addresses      = var.threat_detection_email_addresses

  retention_days = var.threat_detection_retention_days
}
