# =============================================================================
# STAGING ENVIRONMENT - TERRAFORM BACKEND
# =============================================================================

terraform {
  backend "azurerm" {
    # These values are provided via -backend-config in CI/CD
    # resource_group_name  = "tfstate-rg"
    # storage_account_name = "tfstateXXXXX"
    # container_name       = "tfstate"
    # key                  = "staging/terraform.tfstate"
    
    use_oidc = true
  }
}
