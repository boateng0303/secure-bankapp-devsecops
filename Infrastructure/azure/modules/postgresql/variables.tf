# =============================================================================
# POSTGRESQL VARIABLES
# =============================================================================

variable "server_name" {
  description = "Name of the PostgreSQL server"
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

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be 11, 12, 13, 14, 15, or 16."
  }
}

variable "sku_name" {
  description = "SKU name (e.g., B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768  # 32 GB
}

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
  default     = "pgadmin"
}

variable "administrator_password" {
  description = "Administrator password (auto-generated if not provided)"
  type        = string
  default     = null
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID for private access"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "1"
}

variable "high_availability_mode" {
  description = "High availability mode (Disabled, SameZone, ZoneRedundant)"
  type        = string
  default     = "ZoneRedundant"

  validation {
    condition     = contains(["Disabled", "SameZone", "ZoneRedundant"], var.high_availability_mode)
    error_message = "High availability mode must be Disabled, SameZone, or ZoneRedundant."
  }
}

variable "standby_availability_zone" {
  description = "Standby availability zone"
  type        = string
  default     = "2"
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 35

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = true
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = ["appdb"]
}

variable "enable_aad_auth" {
  description = "Enable Azure AD authentication"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID for AAD auth"
  type        = string
  default     = null
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = false
}

variable "enable_pgaudit" {
  description = "Enable pgaudit extension"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
