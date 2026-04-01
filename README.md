 # Reuel Banking App

Reuel Banking App gives you a simple, fast, protected banking experience. You run it with an Angular frontend and a Spring Boot backend. The system helps you test modern DevSecOps skills through a realistic workflow.

## Architecture

![Reuel Banking Architecture](./Images/Secure%20Bank%20Architecture.gif)

The diagram shows our DevSecOps pipeline:
- **Infrastructure Pipeline**: GitHub Actions → Terraform → Azure
- **CI/CD Pipeline**: GitHub → GitHub Actions → ArgoCD → Kubernetes
- **Security**: Trivy, SonarCloud scanning with email alerts
- **Monitoring**: Prometheus, Grafana with Slack alerts
- **Container Registry**: Azure Container Registry (ACR)
- **Database**: MySQL deployed in Kubernetes

## Features
- User registration and login with JWT authentication.
- Role based access control.
- Account dashboard with balances and recent transactions.
- Secure API calls through HTTPS and input validation.
- Angular UI served behind Nginx.
- Spring Boot backend with security filters and strong defaults.
- CI and CD pipeline with code scanning, dependency checks, and container scanning.
- Kubernetes ready container images.

## Technology stack
- Angular 17 frontend.
- Spring Boot 3 backend.
- PostgreSQL database.
- Nginx static hosting.
- Docker and Kubernetes deployment.
- GitHub Actions pipeline.

## Project structure
- banking-app-frontend contains the Angular UI.
- banking-app-backend contains the Spring Boot service.
- manifests contains Kubernetes deployment files.
- docker contains Dockerfiles and Nginx configs.



## How to run locally
- Install Node and Java 17.
- Install Angular CLI.
- Run npm install in the frontend folder.
- Run ng serve to start the UI.
- Run mvn spring-boot:run in the backend folder.
- Access the app at http://localhost:4200.

## Security approach
- Input validation on every request.
- Strong password rules.
- JWT based sessions with short lifetimes.
- Security headers in Nginx.
- Dependency checks through GitHub Actions.
- Container scans for every image.

## Project Structure

```
├── banking-app/
│   ├── banking-app-frontend/    # Angular frontend
│   └── banking-app-backend/     # Spring Boot backend
│
├── argocd/                      # ArgoCD GitOps manifests
│   ├── frontend/                # Frontend Rollout + Service
│   └── backend/                 # Backend Rollout + Service
│
├── shared/                      # Cluster-wide resources
│   ├── namespace.yaml           # banking namespace
│   ├── ingress.yaml             # Ingress for frontend + backend
│   ├── configmap.yaml           # Application configuration
│   ├── secret-providerclass.yaml # Azure Key Vault integration
│   ├── cluster-issuer.yaml      # TLS certificate issuer
│   └── install-prerequisites.sh # One-time cluster setup
│
├── monitoring/                  # Prometheus + Alertmanager
│   ├── install-monitoring.sh    # Install kube-prometheus-stack
│   ├── alertmanager-config.yaml # Alert routing + Slack
│   ├── demo-alerts.yaml         # PrometheusRule alerts
│   └── test-alerts.sh           # Test script for alerts
│
├── autoremediation/             # Auto-fix service
│   ├── autoremediation.py       # FastAPI webhook handler
│   ├── Dockerfile               # Container build
│   ├── deployment.yaml          # K8s Deployment + Service
│   └── rbac.yaml                # ClusterRole + Binding
│
└── .github/workflows/           # CI/CD Pipelines
    ├── backend-ci.yaml          # Backend build, test, push to ACR
    ├── frontend-ci.yaml         # Frontend build, test, push to ACR
    ├── security-scan.yaml       # SonarCloud + Trivy + Email (manual)
    ├── shared-infra.yaml        # Deploy shared resources
    └── autoremediation.yaml     # Build + deploy autoremediation
```

## Deployment Order

1. **Terraform** - Create AKS cluster, ACR, Key Vault
2. **Prerequisites** - `./shared/install-prerequisites.sh`
3. **Create secrets** - Add secrets to Azure Key Vault
4. **Shared Infra** - Run `shared-infra` pipeline
5. **Monitoring** - `./monitoring/install-monitoring.sh`
6. **Applications** - Deploy frontend/backend via ArgoCD

## Important Notes

### Monitoring Setup (Slack Alerts)

Before running the monitoring install script, set the Slack webhook URL as an environment variable:

```bash
# 1. Set the environment variable
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/xxx/yyy/zzz"

# 2. Run the script
./monitoring/install-monitoring.sh
```

The script uses `envsubst` to inject the webhook URL into the Alertmanager config. Without this, Slack notifications will not work.

### GitHub Secrets & Variables

**Secrets** (sensitive - store in GitHub Secrets):
- `AZURE_CLIENT_ID` - App Registration for OIDC
- `AZURE_TENANT_ID` - Azure AD Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `MANAGED_IDENTITY_CLIENT_ID` - For pods to access Key Vault
- `SONAR_TOKEN` - SonarCloud authentication
- `SONAR_ORGANIZATION` - SonarCloud org name
- `SONAR_PROJECT_KEY_BACKEND` - SonarCloud project key
- `SONAR_PROJECT_KEY_FRONTEND` - SonarCloud project key
- `GMAIL_USERNAME` - For email notifications
- `GMAIL_APP_PASSWORD` - Gmail app password (not regular password)
- `NOTIFICATION_EMAIL` - Where to send alerts
- `SLACK_WEBHOOK_URL` - Slack incoming webhook

**Variables** (non-sensitive - store in GitHub Variables):
- `AZURE_RESOURCE_GROUP` - e.g., `banking-dev-rg`
- `AKS_CLUSTER_NAME` - e.g., `banking-dev-aks`
- `ACR_NAME` - e.g., `bankingdevacr`
- `KEYVAULT_NAME` - e.g., `banking-dev-kv-abc123`

## Quick Links

- **Frontend**: https://kwasiboateng.lol
- **Backend API**: https://kwasiboateng.lol/api
- **Grafana**: `kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring`

---

## Detailed Deployment Guide

This project uses a combination of **manual/local setup** (one-time) and **automated CI/CD pipelines** (ongoing).

### Phase 1: Infrastructure Setup (Manual/Local - One Time)

These steps are done **locally** before any pipeline runs:

| Step | Task | Where | Command/Action |
|------|------|-------|----------------|
| 1.1 | Create Azure Resources | Azure Portal/CLI | AKS, MySQL, Key Vault, ACR (via Terraform in separate repo) |
| 1.2 | Configure OIDC for GitHub Actions | Azure CLI | `az ad app federated-credential create` |
| 1.3 | Add GitHub Secrets | GitHub UI | `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `MY_TOKEN`, `SONAR_TOKEN` |
| 1.4 | Add GitHub Variables | GitHub UI | `AZURE_RESOURCE_GROUP`, `AKS_CLUSTER_NAME`, `ACR_NAME`, `KEYVAULT_NAME`, `MANAGED_IDENTITY_CLIENT_ID`, `AZURE_TENANT_ID` |
| 1.5 | Create Key Vault Secrets | Azure CLI | `az keyvault secret set --vault-name <kv> --name db-username --value <value>` |
| 1.6 | Connect to AKS | Local Terminal | `az aks get-credentials --resource-group <rg> --name <cluster>` |
| 1.7 | Install Prerequisites | Local Terminal | `bash shared/install-prerequisites.sh` (Envoy Gateway, cert-manager, CSI driver) |

**Key Vault Secrets to Create:**
```bash
az keyvault secret set --vault-name banking-prod-kv-7frcnk --name db-username --value "<mysql-username>"
az keyvault secret set --vault-name banking-prod-kv-7frcnk --name db-password --value "<mysql-password>"
az keyvault secret set --vault-name banking-prod-kv-7frcnk --name jwt-secret --value "<your-jwt-secret>"
```

---

### Phase 2: Shared Infrastructure (Pipeline - One Time)

Run **once** after Phase 1 is complete:

| Pipeline | Trigger | Deploys |
|----------|---------|---------|
| `shared-infra.yaml` | Manual (`workflow_dispatch`) | Namespace, ConfigMap, SecretProviderClass, Gateway, HTTPRoutes, ClusterIssuer |

**How to Run:**
1. Go to GitHub → Actions → "Deploy Shared Infrastructure"
2. Click "Run workflow"
3. Type `deploy` to confirm
4. Wait for completion

---

### Phase 3: Application Deployment (Pipeline - Automated)

These run **automatically** on code changes:

| Pipeline | Trigger | What It Does |
|----------|---------|--------------|
| `backend-ci.yaml` | Push to `main` (backend changes) | Build, test, scan, push Docker image to ACR, update ArgoCD rollout |
| `frontend-ci.yaml` | Push to `main` (frontend changes) | Build, test, push Docker image to ACR, update ArgoCD rollout |
| `security-scan.yaml` | Push/PR | SonarCloud analysis, Trivy scan, OWASP dependency check |

**Deployment Flow:**
```
Code Push → GitHub Actions → Docker Build → Push to ACR → Update Rollout YAML → ArgoCD Syncs → Kubernetes
```

---

### Phase 4: DNS Configuration (Manual - One Time)

After shared infrastructure is deployed:

| Step | Task | Where |
|------|------|-------|
| 4.1 | Get Gateway External IP | `kubectl get gateway app-gateway -n banking` |
| 4.2 | Create DNS A Record | Your DNS Provider (e.g., Cloudflare) |

**DNS Configuration:**
```
Type: A
Name: kwasiboateng.lol (or @)
Value: <Gateway-External-IP>
TTL: Auto
```

---

### Summary: What's Manual vs Pipeline

| Task | Manual (Local) | Pipeline (Automated) |
|------|----------------|---------------------|
| Azure Infrastructure (AKS, MySQL, KV) | ✅ | ❌ |
| GitHub Secrets/Variables | ✅ | ❌ |
| Key Vault Secrets | ✅ | ❌ |
| Install Prerequisites (Envoy, cert-manager) | ✅ | ❌ |
| DNS Configuration | ✅ | ❌ |
| Shared K8s Resources (Gateway, ConfigMap) | ❌ | ✅ (`shared-infra.yaml`) |
| Backend Build & Deploy | ❌ | ✅ (`backend-ci.yaml`) |
| Frontend Build & Deploy | ❌ | ✅ (`frontend-ci.yaml`) |
| Security Scanning | ❌ | ✅ (`security-scan.yaml`) |

---

### Complete Deployment Checklist

```
□ Phase 1: Infrastructure (Local)
  □ 1.1 Azure resources created (AKS, MySQL, Key Vault, ACR)
  □ 1.2 OIDC federated credentials configured
  □ 1.3 GitHub Secrets added
  □ 1.4 GitHub Variables added
  □ 1.5 Key Vault secrets created (db-username, db-password, jwt-secret)
  □ 1.6 Connected to AKS cluster
  □ 1.7 Prerequisites installed (Envoy Gateway, cert-manager, CSI driver)

□ Phase 2: Shared Infrastructure (Pipeline)
  □ 2.1 Run shared-infra.yaml workflow
  □ 2.2 Verify Gateway has External IP

□ Phase 3: DNS (Local)
  □ 3.1 Configure DNS A record pointing to Gateway IP
  □ 3.2 Wait for DNS propagation (5-30 mins)
  □ 3.3 Verify TLS certificate is issued

□ Phase 4: Application (Pipeline - Automated)
  □ 4.1 Push code to trigger backend-ci.yaml
  □ 4.2 Push code to trigger frontend-ci.yaml
  □ 4.3 Verify pods are running: kubectl get pods -n banking
```