# 🚀 Production-Grade Terraform Azure Infrastructure

This repository contains a comprehensive, production-grade Terraform setup for Azure infrastructure with GitHub Actions CI/CD.

## 📋 Table of Contents

- [Structure](#-structure)
- [Key Features](#-key-features)
- [Features](#-features)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Setup Guide](#-setup-guide)
- [GitHub Actions Workflows](#-github-actions-workflows)
- [Modules](#-modules)
- [Environments](#-environments)
- [Security](#-security)
- [Cost Optimization](#-cost-optimization)
- [Troubleshooting](#-troubleshooting)

## 📁 Structure

```
.github/
├── actions/
│   └── terraform-azure/
│       └── action.yml              # Enhanced composite action
└── workflows/
    ├── terraform-pr.yml            # PR validation workflow
    ├── terraform-deploy.yml        # Deployment workflow
    ├── terraform-destroy.yml       # Destruction workflow
    └── terraform-drift.yml         # Drift detection workflow

infrastructure/azure/
├── modules/
│   ├── resource-group/             # Resource Group module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── networking/                 # VNet, Subnets, NSGs, NAT Gateway
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── aks/                        # Azure Kubernetes Service
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── postgresql/                 # PostgreSQL Flexible Server
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── keyvault/                   # Azure Key Vault
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── acr/                        # Azure Container Registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/                 # Log Analytics, App Insights, Alerts
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── dashboard.json.tpl
├── environments/
│   ├── dev/                        # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars.example
│   ├── staging/                    # Staging environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── backend.tf
│   └── prod/                       # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── backend.tf
├── scripts/
│   ├── setup-backend.sh            # State backend setup
│   └── setup-oidc.sh               # OIDC authentication setup
├── README.md                       # This documentation
└── .gitignore
```

## ⚡ Key Features

| Feature | Description |
|---------|-------------|
| **OIDC Authentication** | Passwordless Azure authentication - no secrets stored in GitHub! |
| **Security Scanning** | Integrated tfsec, Checkov, and TFLint for security & quality |
| **Cost Estimation** | Infracost integration shows cost impact on every PR |
| **Drift Detection** | Scheduled checks every 6 hours with auto-created issues |
| **PR Comments** | Detailed plan output posted directly on pull requests |
| **Multi-Environment** | Progressive deployment: Dev → Staging → Prod |
| **Private Endpoints** | All services connected via private network |
| **Zone Redundancy** | HA configuration for production workloads |
| **Workload Identity** | Secure pod authentication with Azure AD |
| **Auto-scaling** | AKS cluster and node pool auto-scaling |

## ✨ Features

### Infrastructure as Code
- **Modular Design**: Reusable Terraform modules for all Azure resources
- **Multi-Environment**: Separate configurations for dev, staging, and production
- **State Management**: Azure Storage backend with locking and encryption
- **Version Control**: All infrastructure changes tracked in Git

### CI/CD Pipeline
- **OIDC Authentication**: Passwordless authentication with Azure (no secrets!)
- **PR Validation**: Automatic plan on pull requests with detailed comments
- **Security Scanning**: tfsec, Checkov, and TFLint integration
- **Cost Estimation**: Infracost integration for cost visibility
- **Drift Detection**: Scheduled detection of infrastructure drift
- **Multi-Environment Deployment**: Progressive rollout from dev → staging → prod

### Security
- **Private Endpoints**: All services connected via private network
- **RBAC**: Azure AD integration with role-based access
- **Key Vault**: Centralized secrets management
- **Network Isolation**: VNet with NSGs and network policies
- **Compliance**: PCI-DSS ready configuration for banking

### Monitoring
- **Log Analytics**: Centralized logging and monitoring
- **Application Insights**: APM for applications
- **Alerts**: Metric and log-based alerting
- **Container Insights**: AKS monitoring

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Azure Cloud                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                         Virtual Network                            │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │  │
│  │  │   AKS Subnet    │  │  Database Subnet │  │  PE Subnet      │    │  │
│  │  │                 │  │                  │  │                 │    │  │
│  │  │  ┌───────────┐  │  │  ┌────────────┐  │  │ ┌─────────────┐ │    │  │
│  │  │  │    AKS    │  │  │  │ PostgreSQL │  │  │ │Private      │ │    │  │
│  │  │  │  Cluster  │◄─┼──┼──┤  Flexible  │  │  │ │Endpoints    │ │    │  │
│  │  │  └───────────┘  │  │  │   Server   │  │  │ │             │ │    │  │
│  │  │                 │  │  └────────────┘  │  │ │ • KeyVault  │ │    │  │
│  │  └─────────────────┘  └─────────────────┘  │ │ • ACR       │ │    │  │
│  │                                            │ └─────────────┘ │    │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐             │
│  │   Key Vault    │  │      ACR       │  │  Log Analytics │             │
│  │   (Premium)    │  │   (Premium)    │  │   + AppInsights│             │
│  └────────────────┘  └────────────────┘  └────────────────┘             │
└─────────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI (`az`) installed and logged in
- Terraform >= 1.5.0
- GitHub repository with Actions enabled

### 1. Set Up Azure Backend

```bash
# Run the setup script
cd infrastructure/azure/scripts
chmod +x setup-backend.sh
./setup-backend.sh
```

### 2. Configure OIDC for GitHub Actions

```bash
# Set your GitHub org and repo
export GITHUB_ORG="your-org"
export GITHUB_REPO="your-repo"

chmod +x setup-oidc.sh
./setup-oidc.sh
```

### 3. Add GitHub Secrets

Go to your repository **Settings > Secrets and variables > Actions** and add:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Azure AD Application ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |
| `INFRACOST_API_KEY` | (Optional) Infracost API key |

### 4. Add GitHub Variables

| Variable | Description |
|----------|-------------|
| `TF_BACKEND_RESOURCE_GROUP` | Resource group for state storage |
| `TF_BACKEND_STORAGE_ACCOUNT` | Storage account name |

### 5. Create GitHub Environments

Create these environments in **Settings > Environments**:

1. **dev** - No protection rules
2. **staging** - Require reviewer approval
3. **production** - Require reviewer approval + wait timer

### 6. Deploy!

```bash
# Push to main to trigger deployment
git push origin main
```

## 📖 Setup Guide

### Local Development

```bash
# Navigate to environment
cd infrastructure/azure/environments/dev

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstateXXXX" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/terraform.tfstate"

# Plan
terraform plan

# Apply
terraform apply
```

### Required Azure AD Groups

Create these Azure AD groups for RBAC:

1. **AKS Cluster Admins** - Full cluster access
2. **Key Vault Admins** - Manage secrets and keys
3. **DevOps Team** - CI/CD operations

## 🔄 GitHub Actions Workflows

### `terraform-pr.yml` - PR Validation

Triggered on pull requests to `main`:
- Detects changed environments
- Runs `terraform plan` for affected environments
- Posts plan output as PR comment
- Runs security scans (tfsec, Checkov)
- Estimates costs with Infracost

### `terraform-deploy.yml` - Deployment

Triggered on push to `main` or manual dispatch:
- **Dev**: Auto-deploys
- **Staging**: Deploys after dev success
- **Production**: Requires manual approval

### `terraform-destroy.yml` - Infrastructure Destruction

Manual workflow with safety checks:
- Requires confirmation (type environment name)
- Requires reason for destruction
- Creates backup before destroy
- Extra approval gate for production

### `terraform-drift.yml` - Drift Detection

Scheduled every 6 hours:
- Detects configuration drift
- Creates GitHub issue if drift found
- Sends notifications (Slack/email)
- Auto-closes issue when drift resolved

## 📦 Modules

| Module | Description |
|--------|-------------|
| `resource-group` | Azure Resource Group with optional delete lock |
| `networking` | VNet, Subnets, NSGs, NAT Gateway, Private DNS |
| `aks` | Azure Kubernetes Service with node pools |
| `postgresql` | Azure Database for PostgreSQL Flexible Server |
| `keyvault` | Azure Key Vault with private endpoint |
| `acr` | Azure Container Registry with geo-replication |
| `monitoring` | Log Analytics, App Insights, Alerts |

## 🌍 Environments

| Environment | Purpose | HA | Private | Security |
|-------------|---------|-----|---------|----------|
| **dev** | Development/testing | No | No | Basic |
| **staging** | Pre-production | Partial | Yes | Standard |
| **prod** | Production | Full | Yes | Maximum |

### Environment Comparison

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| AKS SKU | Free | Standard | Premium |
| AKS Nodes | 1-3 | 2-8 | 3-20 |
| Zone Redundancy | No | 2 zones | 3 zones |
| PostgreSQL HA | Disabled | SameZone | ZoneRedundant |
| Geo Backup | No | No | Yes |
| Private Cluster | No | Yes | Yes |
| Key Vault | Standard | Standard | Premium |
| Delete Lock | No | Yes | Yes |

## 🔒 Security

### Network Security
- All production resources in private VNet
- Private endpoints for PaaS services
- NSG rules restricting traffic
- NAT Gateway for outbound

### Authentication
- OIDC for GitHub Actions (no stored credentials)
- Azure AD RBAC for all resources
- Workload Identity for AKS pods
- Managed Identities where possible

### Secrets Management
- Key Vault for all secrets
- Secret rotation enabled
- Audit logging enabled

### Compliance
- PCI-DSS ready configuration
- Audit logging (1 year retention)
- pgaudit for database
- Microsoft Defender enabled

## 💰 Cost Optimization

### Development
- Use `Free` tier AKS
- Minimal node counts
- Burstable VM sizes
- No geo-redundancy

### Production
- Enable Spot node pools for batch workloads
- Right-size VMs based on metrics
- Use reserved instances for predictable workloads
- Set Log Analytics daily cap

### Infracost Integration

Enable cost estimation in PRs:

1. Get API key from [infracost.io](https://www.infracost.io/)
2. Add `INFRACOST_API_KEY` secret to GitHub

## 🔧 Troubleshooting

### Common Issues

**Terraform state lock**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

**OIDC authentication fails**
- Verify federated credential subjects match exactly
- Check GitHub environment names
- Ensure App has correct role assignments

**Private cluster access**
```bash
# Use Azure Bastion or VPN
az aks command invoke \
  --resource-group <rg> \
  --name <cluster> \
  --command "kubectl get nodes"
```

**Drift detection shows false positives**
- Some Azure defaults may differ from Terraform
- Add to `lifecycle { ignore_changes = [...] }` if acceptable

### Useful Commands

```bash
# Get AKS credentials
az aks get-credentials -g <rg> -n <cluster>

# List Key Vault secrets
az keyvault secret list --vault-name <vault>

# Check PostgreSQL connectivity
az postgres flexible-server show-connection-string \
  --server-name <server> \
  --database-name <db>
```

## 📚 Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)
- [GitHub Actions OIDC with Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)

## 📝 License

This project is licensed under the MIT License.
