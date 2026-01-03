# =============================================================================
# AZURE SQL DATABASE MODULE - VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "server_name" {
  description = "Name of the Azure SQL Server"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

# -----------------------------------------------------------------------------
# Authentication
# -----------------------------------------------------------------------------

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "azuread_admin_object_id" {
  description = "Object ID of the Azure AD admin"
  type        = string
  default     = null
}

variable "azuread_admin_login" {
  description = "Login name for Azure AD admin"
  type        = string
  default     = null
}

variable "azuread_authentication_only" {
  description = "Use Azure AD authentication only"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# SQL Server Configuration
# -----------------------------------------------------------------------------

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "databases" {
  description = "List of database names to create"
  type        = list(string)
  default     = ["appdb"]
}

variable "sku_name" {
  description = "SKU name for the database (Basic, S0, S1, GP_S_Gen5_1, etc.)"
  type        = string
  default     = "Basic"
}

variable "max_size_gb" {
  description = "Maximum size of the database in GB"
  type        = number
  default     = 2
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "read_scale" {
  description = "Enable read scale-out"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Serverless Configuration (for GP_S_* SKUs)
# -----------------------------------------------------------------------------

variable "auto_pause_delay_in_minutes" {
  description = "Auto-pause delay for serverless (use -1 to disable)"
  type        = number
  default     = -1
}

variable "min_capacity" {
  description = "Minimum capacity for serverless"
  type        = number
  default     = null
}

# -----------------------------------------------------------------------------
# Backup Configuration
# -----------------------------------------------------------------------------

variable "backup_retention_days" {
  description = "Short-term backup retention in days (7-35)"
  type        = number
  default     = 7
}

variable "backup_interval_in_hours" {
  description = "Backup interval in hours (12 or 24)"
  type        = number
  default     = 12
}

variable "enable_long_term_retention" {
  description = "Enable long-term backup retention"
  type        = bool
  default     = false
}

variable "ltr_weekly_retention" {
  description = "Weekly retention (ISO 8601 format, e.g., P1W)"
  type        = string
  default     = "P1W"
}

variable "ltr_monthly_retention" {
  description = "Monthly retention (ISO 8601 format, e.g., P1M)"
  type        = string
  default     = "P1M"
}

variable "ltr_yearly_retention" {
  description = "Yearly retention (ISO 8601 format, e.g., P1Y)"
  type        = string
  default     = "P1Y"
}

variable "ltr_week_of_year" {
  description = "Week of year for yearly backup"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = true
}

variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs for VNet rules"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for SQL"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Monitoring & Security
# -----------------------------------------------------------------------------

variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "enable_auditing" {
  description = "Enable server auditing"
  type        = bool
  default     = false
}

variable "audit_storage_endpoint" {
  description = "Storage account endpoint for audit logs"
  type        = string
  default     = null
}

variable "audit_storage_access_key" {
  description = "Storage account access key for audit logs"
  type        = string
  default     = null
  sensitive   = true
}

variable "audit_retention_days" {
  description = "Audit log retention in days"
  type        = number
  default     = 90
}

variable "enable_threat_detection" {
  description = "Enable Advanced Threat Protection"
  type        = bool
  default     = false
}

variable "threat_detection_email_admins" {
  description = "Email account admins on threat detection"
  type        = bool
  default     = true
}

variable "threat_detection_email_addresses" {
  description = "Email addresses for threat detection alerts"
  type        = list(string)
  default     = []
}

variable "threat_detection_retention_days" {
  description = "Threat detection log retention in days"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
