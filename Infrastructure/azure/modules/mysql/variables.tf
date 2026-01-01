# =============================================================================
# MYSQL VARIABLES
# =============================================================================

variable "server_name" {
  description = "Name of the MySQL server"
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

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.21"

  validation {
    condition     = contains(["5.7", "8.0.21"], var.mysql_version)
    error_message = "MySQL version must be 5.7 or 8.0.21."
  }
}

variable "sku_name" {
  description = "SKU name (e.g., B_Standard_B1ms, GP_Standard_D2ds_v4, MO_Standard_E4ds_v4)"
  type        = string
  default     = "GP_Standard_D2ds_v4"
}

variable "storage_size_gb" {
  description = "Storage size in GB (20-16384)"
  type        = number
  default     = 32

  validation {
    condition     = var.storage_size_gb >= 20 && var.storage_size_gb <= 16384
    error_message = "Storage size must be between 20 and 16384 GB."
  }
}

variable "storage_iops" {
  description = "Storage IOPS (360-20000)"
  type        = number
  default     = 360
}

variable "storage_auto_grow_enabled" {
  description = "Enable storage auto-grow"
  type        = bool
  default     = true
}

variable "io_scaling_enabled" {
  description = "Enable IO scaling"
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "Administrator login name"
  type        = string
  default     = "mysqladmin"
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
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
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

variable "database_charset" {
  description = "Default character set for databases"
  type        = string
  default     = "utf8mb4"
}

variable "database_collation" {
  description = "Default collation for databases"
  type        = string
  default     = "utf8mb4_unicode_ci"
}

# AAD Authentication
variable "aad_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
  default     = null
}

variable "aad_admin_login" {
  description = "Azure AD admin login name"
  type        = string
  default     = null
}

variable "aad_admin_identity_id" {
  description = "User assigned identity ID for AAD admin"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = null
}

# Network
variable "allow_azure_services" {
  description = "Allow Azure services to access the server"
  type        = bool
  default     = false
}

variable "allowed_ip_addresses" {
  description = "Map of allowed IP address ranges"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

# Performance
variable "slow_query_time" {
  description = "Long query time threshold in seconds"
  type        = string
  default     = "2"
}

variable "innodb_buffer_pool_size" {
  description = "InnoDB buffer pool size in bytes"
  type        = string
  default     = null
}

variable "max_connections" {
  description = "Maximum number of connections"
  type        = string
  default     = null
}

# Audit & Security
variable "enable_audit_log" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}

variable "enable_customer_managed_key" {
  description = "Enable customer managed key encryption"
  type        = bool
  default     = false
}

variable "identity_ids" {
  description = "User assigned identity IDs for CMK"
  type        = list(string)
  default     = []
}

# Monitoring
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
