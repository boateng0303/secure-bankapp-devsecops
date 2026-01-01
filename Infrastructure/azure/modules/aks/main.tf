# =============================================================================
# AZURE KUBERNETES SERVICE (AKS) MODULE
# Production-grade AKS cluster with security best practices
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
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# User Assigned Identity for AKS
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AKS Cluster
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # Private cluster settings
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null

  # SKU tier (Free, Standard, Premium)
  sku_tier = var.sku_tier

  # Automatic channel upgrade
  automatic_channel_upgrade = var.automatic_channel_upgrade

  # Node resource group
  node_resource_group = "${var.cluster_name}-nodes-rg"

  # Default node pool
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool_vm_size
    node_count                   = var.system_node_pool_count
    min_count                    = var.system_node_pool_min_count
    max_count                    = var.system_node_pool_max_count
    enable_auto_scaling          = var.enable_auto_scaling
    max_pods                     = var.max_pods_per_node
    os_disk_size_gb              = var.os_disk_size_gb
    os_disk_type                 = "Managed"
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = true
    zones                        = var.availability_zones

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }

    tags = var.tags
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Network profile
  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type

    load_balancer_profile {
      managed_outbound_ip_count = var.outbound_type == "loadBalancer" ? var.outbound_ip_count : null
    }
  }

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = var.enable_azure_rbac
    admin_group_object_ids = var.admin_group_object_ids
  }

  # Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # OIDC and Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = var.enable_workload_identity

  # Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  # HTTP Application Routing (disabled for production)
  http_application_routing_enabled = false

  # Container Insights
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Microsoft Defender
  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4, 5]
    }
  }

  # Auto-scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
    empty_bulk_delete_max            = 10
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
    ]
  }
}

# -----------------------------------------------------------------------------
# User Node Pool (for workloads)
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_pool_vm_size
  node_count            = var.user_node_pool_count
  min_count             = var.user_node_pool_min_count
  max_count             = var.user_node_pool_max_count
  enable_auto_scaling   = var.enable_auto_scaling
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = var.os_disk_size_gb
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  mode                  = "User"

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload-type" = "general"
  }

  node_taints = []

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# -----------------------------------------------------------------------------
# Spot Node Pool (Optional - for cost savings)
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.enable_spot_node_pool ? 1 : 0

  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.spot_node_pool_vm_size
  min_count             = 0
  max_count             = var.spot_node_pool_max_count
  enable_auto_scaling   = true
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = var.os_disk_size_gb
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = var.spot_max_price

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    "nodepool-type"                      = "spot"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}

# -----------------------------------------------------------------------------
# Role Assignments
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.enable_acr_pull ? 1 : 0

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# -----------------------------------------------------------------------------
# Diagnostic Settings
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.enable_diagnostics ? 1 : 0

  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
