# =============================================================================
# PRODUCTION ENVIRONMENT - MAIN CONFIGURATION
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_subscription" "current" {}

# Generate random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# Local Variables
# -----------------------------------------------------------------------------

locals {
  environment = "prod"
  prefix      = "${var.project_name}-${local.environment}"
  location    = var.location

  common_tags = {
    Environment  = local.environment
    Project      = var.project_name
    ManagedBy    = "Terraform"
    CostCenter   = var.cost_center
    Owner        = var.owner_email
    Compliance   = "PCI-DSS"  # Banking compliance
    DataClass    = "Confidential"
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name               = "${local.prefix}-rg"
  location           = local.location
  enable_delete_lock = true  # Always protected in production
  tags               = local.common_tags
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = module.resource_group.name
  vnet_name           = "${local.prefix}-vnet"

  address_space                = ["10.2.0.0/16"]  # Production CIDR
  aks_subnet_cidr              = "10.2.0.0/22"
  database_subnet_cidr         = "10.2.4.0/24"
  appgw_subnet_cidr            = "10.2.5.0/24"
  private_endpoint_subnet_cidr = "10.2.6.0/24"
  bastion_subnet_cidr          = "10.2.7.0/26"

  enable_application_gateway = true
  enable_nat_gateway         = true
  enable_bastion             = true  # Bastion for secure access

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = module.resource_group.name
  subscription_id     = data.azurerm_subscription.current.subscription_id

  log_analytics_name = "${local.prefix}-law"
  retention_in_days  = 365  # Full year for compliance

  enable_container_insights   = true
  enable_security_insights    = true  # Enable Sentinel for prod
  enable_application_insights = true
  app_insights_name           = "${local.prefix}-ai"

  alert_email_receivers   = var.alert_email_receivers
  alert_sms_receivers     = var.alert_sms_receivers
  alert_webhook_receivers = var.alert_webhook_receivers

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Azure Container Registry
# -----------------------------------------------------------------------------

module "acr" {
  source = "../../modules/acr"

  name                = replace("${var.project_name}${local.environment}acr", "-", "")
  location            = local.location
  resource_group_name = module.resource_group.name

  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = true
  data_endpoint_enabled         = true
  enable_content_trust          = true

  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.acr_private_dns_zone_id

  # Geo-replication for DR
  georeplications = var.acr_georeplications

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

module "keyvault" {
  source = "../../modules/keyvault"

  name                = "${var.project_name}-${local.environment}-kv-${random_string.suffix.result}"
  location            = local.location
  resource_group_name = module.resource_group.name

  sku_name                      = "premium"  # Premium for HSM keys
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = true  # Allow GitHub Actions access
  network_acls_default_action   = "Allow"  # Required for Terraform access
  enabled_for_disk_encryption   = true

  enable_private_endpoint    = false  # Disable for now to avoid access issues
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.keyvault_private_dns_zone_id

  admin_object_ids = var.keyvault_admin_object_ids

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

module "aks" {
  source = "../../modules/aks"

  cluster_name        = "${local.prefix}-aks"
  location            = local.location
  resource_group_name = module.resource_group.name
  dns_prefix          = "${var.project_name}-${local.environment}"
  kubernetes_version  = var.kubernetes_version
  environment         = local.environment

  subnet_id = module.networking.aks_subnet_id

  # Private cluster - fully private
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false

  # SKU tier
  sku_tier                  = "Premium"  # Premium for SLA and features
  automatic_channel_upgrade = "stable"

  # Node pools - production sized
  system_node_pool_vm_size   = "Standard_D4s_v5"
  system_node_pool_count     = 3
  system_node_pool_min_count = 3
  system_node_pool_max_count = 5

  user_node_pool_vm_size   = "Standard_D8s_v5"
  user_node_pool_count     = 3
  user_node_pool_min_count = 3
  user_node_pool_max_count = 20

  enable_spot_node_pool    = false  # No spot for production
  spot_node_pool_vm_size   = "Standard_D4s_v5"
  spot_node_pool_max_count = 10

  availability_zones = ["1", "2", "3"]  # Full zone redundancy
  max_pods_per_node  = 50

  # RBAC
  enable_azure_rbac      = true
  admin_group_object_ids = var.aks_admin_group_ids

  # Add-ons
  enable_workload_identity = true
  enable_azure_policy      = true

  # Network
  outbound_type = "userDefinedRouting"  # Use NAT Gateway

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  acr_id                     = module.acr.id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# MySQL
# -----------------------------------------------------------------------------

module "mysql" {
  source = "../../modules/mysql"

  server_name         = "${local.prefix}-mysql"
  location            = local.location
  resource_group_name = module.resource_group.name

  mysql_version   = "8.0.21"
  sku_name        = "GP_Standard_D4ds_v4"  # High performance for prod
  storage_size_gb = 128

  subnet_id           = module.networking.database_subnet_id
  private_dns_zone_id = module.networking.mysql_private_dns_zone_id

  # Full HA for production - no zones specified to let Azure pick available zones
  high_availability_mode    = "ZoneRedundant"

  backup_retention_days        = 35  # Maximum
  geo_redundant_backup_enabled = true

  databases = ["bankingdb"]

  enable_audit_log = true  # Audit logging for compliance

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags

  # Ensure DNS zone is linked to VNet before creating MySQL
  depends_on = [module.networking]
}

# -----------------------------------------------------------------------------
# Store Secrets in Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = "mysql-admin-password"
  value        = module.mysql.administrator_password
  key_vault_id = module.keyvault.id

  content_type = "password"
  expiration_date = timeadd(timestamp(), "8760h")  # 1 year

  depends_on = [module.keyvault]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_key_vault_secret" "mysql_connection_string" {
  name            = "mysql-connection-string"
  value           = module.mysql.connection_string
  key_vault_id    = module.keyvault.id
  content_type    = "connection-string"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [module.keyvault]

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

# -----------------------------------------------------------------------------
# Azure Backup (for additional protection)
# -----------------------------------------------------------------------------

resource "azurerm_recovery_services_vault" "main" {
  name                = "${local.prefix}-rsv"
  location            = local.location
  resource_group_name = module.resource_group.name
  sku                 = "Standard"

  soft_delete_enabled = true
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Update Monitoring with Resource IDs for Alerts
# -----------------------------------------------------------------------------

module "monitoring_alerts" {
  source = "../../modules/monitoring"

  prefix              = "${local.prefix}-alerts"
  location            = local.location
  resource_group_name = module.resource_group.name
  subscription_id     = data.azurerm_subscription.current.subscription_id

  log_analytics_name          = "${local.prefix}-law"
  enable_container_insights   = false
  enable_application_insights = false

  # Enable alerts with explicit boolean flags
  enable_aks_alerts   = true
  enable_mysql_alerts = true
  aks_cluster_id      = module.aks.cluster_id
  mysql_server_id     = module.mysql.server_id

  alert_email_receivers   = var.alert_email_receivers
  alert_sms_receivers     = var.alert_sms_receivers
  alert_webhook_receivers = var.alert_webhook_receivers

  tags = local.common_tags

  depends_on = [module.monitoring]
}
