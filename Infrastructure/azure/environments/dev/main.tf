# =============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
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
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Skip automatic resource provider registration to avoid network timeouts
  # The required providers will be registered on first resource creation
  skip_provider_registration = true
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
  environment = "dev"
  prefix      = "${var.project_name}-${local.environment}"
  location    = var.location

  common_tags = {
    Environment  = local.environment
    Project      = var.project_name
    ManagedBy    = "Terraform"
    CostCenter   = var.cost_center
    Owner        = var.owner_email
    CreatedDate  = timestamp()
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name               = "${local.prefix}-rg"
  location           = local.location
  enable_delete_lock = false  # Dev environment - no lock
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

  address_space                = ["10.0.0.0/16"]
  aks_subnet_cidr              = "10.0.0.0/22"
  database_subnet_cidr         = "10.0.4.0/24"
  appgw_subnet_cidr            = "10.0.5.0/24"
  private_endpoint_subnet_cidr = "10.0.6.0/24"
  bastion_subnet_cidr          = "10.0.7.0/26"

  enable_application_gateway = true
  enable_nat_gateway         = true
  enable_bastion             = false  # Disabled for dev

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
  retention_in_days  = 30  # Shorter retention for dev

  enable_container_insights   = true
  enable_security_insights    = false  # Disabled for dev
  enable_application_insights = true
  app_insights_name           = "${local.prefix}-ai"

  alert_email_receivers = var.alert_email_receivers
  
  # Combine explicit webhook receivers with Slack URL from secret/env var
  alert_webhook_receivers = concat(
    var.alert_webhook_receivers,
    var.slack_webhook_url != "" ? [{
      name        = "slack-alerts"
      service_uri = var.slack_webhook_url
    }] : []
  )

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

  sku                           = "Standard"  # Lower tier for dev
  admin_enabled                 = false
  public_network_access_enabled = true  # Easier for dev
  enable_private_endpoint       = false

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

  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = false  # Disabled for dev
  soft_delete_retention_days    = 7
  public_network_access_enabled = true   # Easier for dev
  enable_private_endpoint       = false
  network_acls_default_action   = "Allow" # Allow GitHub Actions access

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

  # Private cluster - disabled for dev for easier access
  private_cluster_enabled = false

  # SKU tier
  sku_tier = "Free"  # Use Free tier for dev

  # Node pools - smaller for dev
  system_node_pool_vm_size   = "Standard_D2s_v5"
  system_node_pool_count     = 1
  system_node_pool_min_count = 1
  system_node_pool_max_count = 3

  user_node_pool_vm_size   = "Standard_D2s_v5"
  user_node_pool_count     = 1
  user_node_pool_min_count = 1
  user_node_pool_max_count = 5

  enable_spot_node_pool = false
  availability_zones    = []  # No zone redundancy for dev

  # RBAC
  enable_azure_rbac      = true
  admin_group_object_ids = var.aks_admin_group_ids

  # Add-ons
  enable_workload_identity = true
  enable_azure_policy      = false  # Disabled for dev

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
  sku_name        = "B_Standard_B1ms"  # Burstable for dev - cost effective
  storage_size_gb = 32

  subnet_id           = module.networking.database_subnet_id
  private_dns_zone_id = module.networking.mysql_private_dns_zone_id

  # HA disabled for dev - explicit zone 3 for availability
  high_availability_mode = "Disabled"
  availability_zone      = "3"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  databases = ["bankingdb"]

  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  tags = local.common_tags

  # Ensure DNS zone is linked to VNet before creating MySQL
  depends_on = [module.networking]
}

# -----------------------------------------------------------------------------
# Store Secrets in Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name            = "mysql-admin-password"
  value           = module.mysql.administrator_password
  key_vault_id    = module.keyvault.id
  content_type    = "password"
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

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
